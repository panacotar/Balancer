class Order < ApplicationRecord
  belongs_to :user
  belongs_to :campaign
  monetize :amount_cents

  def fulfill_paid_checkout!(session)
    return :unpaid unless paid_for?(session)

    result = nil
    campaign.with_lock do
      campaign.release_expired_checkouts!
      reload
      result = if state == 'paid'
        :already_paid
      elsif state != 'pending'
        :rejected
      elsif campaign.shareholders.sum(:amount).to_d + amount.to_i > campaign.investment_goal.to_d
        update!(state: 'failed')
        :over_capacity
      else
        pledge_amount = amount.to_i
        Shareholder.create!(
          amount: pledge_amount,
          percentage: (campaign.equity * pledge_amount) / campaign.investment_goal,
          status: 'Active',
          user: user,
          campaign: campaign
        )
        update!(state: 'paid')
        :paid
      end
    end

    refund_checkout!(session) if result == :over_capacity
    result
  end

  private

  def paid_for?(session)
    payment_status = session.respond_to?(:payment_status) ? session.payment_status : session['payment_status']
    amount_total = session.respond_to?(:amount_total) ? session.amount_total : session['amount_total']
    payment_status == 'paid' && amount_total == amount_cents
  end

  def refund_checkout!(session)
    payment_intent = session.respond_to?(:payment_intent) ? session.payment_intent : session['payment_intent']
    return if payment_intent.blank?

    Stripe::Refund.create(payment_intent: payment_intent)
  rescue Stripe::StripeError
    nil
  end
end
