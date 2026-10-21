# Stripe authenticates this endpoint by signing the raw request body.
class StripeWebhooksController < ActionController::Base
  skip_forgery_protection

  def create
    secret = ENV['STRIPE_WEBHOOK_SECRET']
    return head :service_unavailable if secret.blank?

    event = Stripe::Webhook.construct_event(request.raw_post, request.headers['Stripe-Signature'], secret)
    return head :bad_request unless event[:livemode] == false

    if event.type == 'checkout.session.completed'
      data = event[:data]
      session = data[:object] if data.is_a?(Stripe::StripeObject)
      StripeCheckout::Fulfill.call(session)
    end
    head :ok
  rescue JSON::ParserError, Stripe::SignatureVerificationError, StripeCheckout::InvalidSession,
         ActiveRecord::RecordNotFound
    head :bad_request
  end
end
