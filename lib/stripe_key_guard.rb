# Rejects live Stripe keys before the demo boots in production.
module StripeKeyGuard
  LIVE_PREFIXES = %w[sk_live_ rk_live_ pk_live_].freeze

  def self.ensure_test_keys!(env, production:)
    return unless production

    %w[STRIPE_SECRET_KEY STRIPE_PUBLISHABLE_KEY].each do |name|
      value = env[name].to_s
      next unless LIVE_PREFIXES.any? { |prefix| value.start_with?(prefix) }

      raise "Refusing to boot: #{name} is a live Stripe key. This demo accepts test keys only."
    end
  end

  def self.ensure_webhook_secret!(env, production:)
    return unless production
    return if env["SECRET_KEY_BASE_DUMMY"].present?
    return if env["STRIPE_WEBHOOK_SECRET"].to_s.strip.present?

    raise "Refusing to boot: STRIPE_WEBHOOK_SECRET is blank. Set the Stripe test webhook signing secret before starting production."
  end
end
