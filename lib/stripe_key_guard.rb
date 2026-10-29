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
end
