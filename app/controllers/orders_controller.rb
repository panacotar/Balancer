class OrdersController < ApplicationController
  def create
    campaign = Campaign.find(params[:campaign_id])
    order = Order.new(campaign: campaign, user: current_user, state: 'pending',
                      campaign_sku: "campaign_#{campaign.id}_#{SecureRandom.hex(8)}")
    authorize order
    order.amount = Order.parse_pledge(params[:pledge_amount])
    campaign.with_lock do
      unless order.valid? && order.amount.to_d <= campaign.available_pledge
        return redirect_to project_path(campaign.project), alert: 'Enter a positive pledge within the available amount.'
      end

      StripeCheckout.ensure_test_mode!
      order.save!
    end
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
    release_canceled_checkout if params[:canceled] == '1'
  end

  private

  def release_canceled_checkout
    @order.with_lock do
      next unless @order.state == 'pending'

      if @order.checkout_session_id.blank?
        @order.update!(state: 'failed')
        next
      end

      StripeCheckout.ensure_test_mode!
      session = Stripe::Checkout::Session.retrieve(@order.checkout_session_id)
      next unless session.livemode == false && session.id == @order.checkout_session_id &&
                  session.client_reference_id == @order.id.to_s && session.currency == 'eur' &&
                  session.amount_total == @order.amount_cents

      case session.status
      when 'open'
        Stripe::Checkout::Session.expire(session.id)
        @order.update!(state: 'failed')
      when 'expired'
        @order.update!(state: 'failed')
      end
    end
  rescue Stripe::StripeError, StripeCheckout::ConfigurationError
    # Keep the reservation when Stripe cannot confirm the session is still open.
  end
end
