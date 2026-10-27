class OrdersController < ApplicationController
  def create
    campaign = Campaign.find(params[:campaign_id])
    order = Order.new(
      campaign: campaign,
      campaign_sku: gen_sku(campaign),
      state: 'pending',
      user: current_user
    )
    authorize order

    amount = parse_pledge(params[:pledge_amount])
    remaining = remaining_pledge(campaign)
    unless amount && amount >= 1 && amount <= remaining
      return redirect_to project_path(campaign.project), alert: 'Enter a pledge between 1 and the amount still available.'
    end

    order.amount = amount
    order.save!

    product_data = { name: order.campaign_sku }
    if campaign.project.photo.attached?
      product_data[:images] = [campaign.project.photo.url]
    end

    session = Stripe::Checkout::Session.create(
      mode: 'payment',
      payment_method_types: ['card'],
      line_items: [{
        quantity: 1,
        price_data: {
          currency: 'eur',
          unit_amount: order.amount_cents,
          product_data: product_data
        }
      }],
      success_url: "#{new_project_shareholder_url(campaign.project)}?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: order_url(order)
    )

    order.update!(checkout_session_id: session.id)
    redirect_to new_order_payment_path(order)
  rescue Stripe::StripeError
    order.destroy if order&.persisted? && order.checkout_session_id.blank?
    redirect_to project_path(campaign.project), alert: 'Checkout is unavailable. Please try again.'
  end

  def show
    @order = current_user.orders.find(params[:id])
    authorize @order
  end

  private

  def gen_sku(campaign)
    campaign.name.gsub(' ', '_') + rand(1..9999).to_s
  end

  def parse_pledge(value)
    text = value.to_s
    return unless text.match?(/\A[1-9]\d*\z/)

    text.to_i
  end

  def remaining_pledge(campaign)
    pledged = 0
    campaign.shareholders.each { |shareholder| pledged += shareholder.amount }
    campaign.investment_goal - pledged
  end
end
