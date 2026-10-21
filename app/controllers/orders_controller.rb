class OrdersController < ApplicationController
  def create
    campaign = Campaign.find(params[:campaign_id])
    order = Order.new(campaign: campaign, user: current_user, state: 'pending',
                      campaign_sku: "campaign_#{campaign.id}_#{SecureRandom.hex(8)}")
    authorize order
    order.amount = Order.parse_pledge(params[:pledge_amount])
    unless order.valid? && order.amount.to_d <= campaign.remaining_pledge
      return redirect_to project_path(campaign.project), alert: 'Enter a positive pledge within the available amount.'
    end

    StripeCheckout.ensure_test_mode!
    order.save!
    session = Stripe::Checkout::Session.create({
      mode: 'payment',
      payment_method_types: ['card'],
      client_reference_id: order.id.to_s,
      metadata: { order_id: order.id.to_s },
      line_items: [{
        price_data: {
          currency: 'eur', unit_amount: order.amount_cents,
          product_data: { name: campaign.name }
        }, quantity: 1
      }],
      success_url: order_url(order),
      cancel_url: order_url(order, canceled: '1')
    }, { idempotency_key: "demo-order-#{order.id}" })
    raise StripeCheckout::InvalidSession unless session.livemode == false

    order.update!(checkout_session_id: session.id)
    redirect_to new_order_payment_path(order), status: :see_other
  rescue ArgumentError
    redirect_to project_path(campaign.project), alert: 'Use a positive amount with at most two decimal places.'
  rescue StripeCheckout::ConfigurationError => error
    redirect_to project_path(campaign.project), alert: error.message
  rescue Stripe::StripeError, StripeCheckout::InvalidSession
    order.update!(state: 'failed') if order.persisted?
    redirect_to project_path(campaign.project), alert: 'Demo checkout is unavailable. Please try again.'
  end

  def show
    @order = current_user.orders.find(params[:id])
    authorize @order
  end
end
