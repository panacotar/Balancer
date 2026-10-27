class ShareholdersController < ApplicationController
  before_action :authenticate_user!

  def new
    authorize Shareholder

    order = current_user.orders.find_by!(checkout_session_id: params[:session_id])
    session = Stripe::Checkout::Session.retrieve(order.checkout_session_id)
    case order.fulfill_paid_checkout!(session)
    when :paid, :already_paid
      redirect_to successfulpledge_path
    when :over_capacity
      redirect_to order_path(order), alert: 'This campaign filled before your payment was confirmed. The payment will be refunded.'
    else
      redirect_to order_path(order), alert: 'Payment was not completed.'
    end
  rescue Stripe::StripeError
    redirect_to order_path(order), alert: 'Payment could not be verified.'
  end
end
