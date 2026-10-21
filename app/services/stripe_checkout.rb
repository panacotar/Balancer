# Balancer is a demo: live payment credentials must never be accepted.
module StripeCheckout
  class ConfigurationError < StandardError; end
  class InvalidSession < StandardError; end

  def self.ensure_test_mode!
    secret = Rails.configuration.stripe[:secret_key].to_s
    public_key = Rails.configuration.stripe[:publishable_key].to_s
    unless secret.start_with?('sk_test_', 'rk_test_') && public_key.start_with?('pk_test_')
      raise ConfigurationError, 'Configure Stripe test keys to use demo checkout.'
    end
  end
end
