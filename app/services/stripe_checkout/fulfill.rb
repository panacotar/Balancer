module StripeCheckout
  class Fulfill
    def self.call(session)
      unless session.is_a?(Stripe::Checkout::Session) && session[:livemode] == false && session[:mode] == 'payment'
        raise InvalidSession
      end
      return unless session[:payment_status] == 'paid' && session[:status] == 'complete'

      order = Order.find_by!(checkout_session_id: session.id)
      metadata = session[:metadata]
      unless metadata.is_a?(Stripe::StripeObject) && metadata[:order_id] == order.id.to_s &&
             session[:client_reference_id] == order.id.to_s &&
             session.amount_total == order.amount_cents && session.currency == 'eur'
        raise InvalidSession
      end

      order.with_lock do
        # Paid and failed are terminal. A later delivery must not raise, or Stripe will retry it.
        return if order.state == 'paid' || order.state == 'failed'
        raise InvalidSession unless order.state == 'pending'

        campaign = order.campaign
        campaign.with_lock do
          if order.amount.to_d > campaign.remaining_pledge
            order.update!(state: 'failed')
            next
          end

          order.create_shareholder!(user: order.user, campaign: campaign, amount: order.amount.to_d,
                                    percentage: campaign.equity.to_d * order.amount.to_d / campaign.investment_goal,
                                    status: 'Active')
          order.update!(state: 'paid')
        end
      end
    end
  end
end
