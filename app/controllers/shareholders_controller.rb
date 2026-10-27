class ShareholdersController < ApplicationController
  before_action :authenticate_user!

  def new
    authorize Shareholder

    order = current_user.orders.find_by!(checkout_session_id: params[:session_id])
    session = Stripe::Checkout::Session.retrieve(order.checkout_session_id)
    unless session.payment_status == 'paid' && session.amount_total == order.amount_cents
      return redirect_to order_path(order), alert: 'Payment was not completed.'
    end

    order.with_lock do
      next unless order.state == 'pending'

      campaign = order.campaign
      pledge_amount = order.amount.to_i
      proj_percent = (campaign.equity * pledge_amount) / campaign.investment_goal
      Shareholder.create!(
        amount: pledge_amount,
        percentage: proj_percent,
        status: 'Active',
        user: current_user,
        campaign: campaign
      )
      order.update!(state: 'paid')
    end

    redirect_to successfulpledge_path
  rescue Stripe::StripeError
    redirect_to order_path(order), alert: 'Payment could not be verified.'
  end
end
