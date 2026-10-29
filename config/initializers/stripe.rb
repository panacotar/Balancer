require Rails.root.join("lib/stripe_key_guard")

StripeKeyGuard.ensure_test_keys!(ENV, production: Rails.env.production?)

Rails.configuration.stripe = {
  publishable_key: ENV["STRIPE_PUBLISHABLE_KEY"],
  secret_key: ENV["STRIPE_SECRET_KEY"]
}

Stripe.api_key = Rails.configuration.stripe[:secret_key]
