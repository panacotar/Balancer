class OrdersController < ApplicationController
  def create
    campaign = Campaign.find(params[:campaign_id])

    order = Order.create!(campaign: campaign, campaign_sku: gen_sku(campaign), amount: monetize_pledge(params[:pledge_amount]), state: 'pending', user: current_user)
    session = Stripe::Checkout::Session.create(
      payment_method_types: ['card'],
      line_items: [{
        name: order.campaign_sku,
        images: [campaign.project.photo.service_url],
        amount: order.amount_cents,
        currency: 'eur',
        quantity: 1
      }],
      success_url: successfulpledge_url,
      cancel_url: order_url(order)
    )
    authorize order

    order.update(checkout_session_id: session.id)
    redirect_to new_order_payment_path(order)
  end

  def show
    @order = current_user.orders.find(params[:id])
    authorize @order
  end

  private

  def gen_sku(campaign)
    campaign.name.gsub(' ', '_') + rand(1..9999).to_s
  end

  def monetize_pledge(amount)
    amount.to_i
  end
end
