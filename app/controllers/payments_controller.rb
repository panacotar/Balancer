class PaymentsController < ApplicationController
  def new
    @order = current_user.orders.where(state: 'pending').find(params[:order_id])
    authorize @order, :show?
    StripeCheckout.ensure_test_mode!
    session = Stripe::Checkout::Session.retrieve(@order.checkout_session_id)
    unless session.livemode == false && session.id == @order.checkout_session_id &&
           session.client_reference_id == @order.id.to_s && session.currency == 'eur' &&
           session.amount_total == @order.amount_cents && session.status == 'open'
      raise StripeCheckout::InvalidSession
    end
    @checkout_url = session.url
    unless @checkout_url&.start_with?('https://checkout.stripe.com/')
      raise StripeCheckout::InvalidSession
    end
  rescue Stripe::StripeError, StripeCheckout::InvalidSession, StripeCheckout::ConfigurationError
    redirect_to order_path(@order), alert: 'This demo checkout is unavailable or has expired.'
  end
end
