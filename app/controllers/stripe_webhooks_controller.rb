class StripeWebhooksController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token
  skip_after_action :verify_authorized

  def create
    event = Stripe::Webhook.construct_event(
      request.raw_post,
      request.env['HTTP_STRIPE_SIGNATURE'],
      ENV['STRIPE_WEBHOOK_SECRET'].to_s
    )
    fulfill_checkout(event) if event['type'] == 'checkout.session.completed'
    head :ok
  rescue JSON::ParserError, Stripe::SignatureVerificationError
    head :bad_request
  end

  private

  def fulfill_checkout(event)
    session = event['data']['object']
    order = Order.find_by(checkout_session_id: session['id'])
    order&.fulfill_paid_checkout!(session)
  end
end
