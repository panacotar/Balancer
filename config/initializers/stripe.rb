Rails.configuration.stripe = {
  publishable_key: ENV['STRIPE_PUBLISHABLE_KEY'],
  secret_key: ENV['STRIPE_SECRET_KEY']
}

Rails.configuration.stripe.each do |name, key|
  next if key.blank?
  allowed = name == :publishable_key ? ['pk_test_'] : ['sk_test_', 'rk_test_']
  raise 'Balancer only supports Stripe test-mode keys.' unless key.start_with?(*allowed)
end
Stripe.api_key = Rails.configuration.stripe[:secret_key]
