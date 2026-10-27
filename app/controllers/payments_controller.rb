class PaymentsController < ApplicationController
  def new
    @order = current_user.orders.where(state: 'pending').find(params[:order_id])
    authorize @order
    session = Stripe::Checkout::Session.retrieve(@order.checkout_session_id)
    @checkout_url = session.url
  rescue Stripe::StripeError
    redirect_to order_path(@order), alert: 'Checkout is unavailable. Please try again.'
  end
end
