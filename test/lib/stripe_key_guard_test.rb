require "test_helper"

class StripeKeyGuardTest < ActiveSupport::TestCase
  test "production refuses live Stripe keys" do
    error = assert_raises(RuntimeError) do
      StripeKeyGuard.ensure_test_keys!(
        { "STRIPE_SECRET_KEY" => "sk_live_secret", "STRIPE_PUBLISHABLE_KEY" => "pk_test_public" },
        production: true
      )
    end
    assert_match "STRIPE_SECRET_KEY", error.message

    error = assert_raises(RuntimeError) do
      StripeKeyGuard.ensure_test_keys!(
        { "STRIPE_SECRET_KEY" => "rk_live_restricted", "STRIPE_PUBLISHABLE_KEY" => "pk_test_public" },
        production: true
      )
    end
    assert_match "STRIPE_SECRET_KEY", error.message

    error = assert_raises(RuntimeError) do
      StripeKeyGuard.ensure_test_keys!(
        { "STRIPE_SECRET_KEY" => "sk_test_secret", "STRIPE_PUBLISHABLE_KEY" => "pk_live_public" },
        production: true
      )
    end
    assert_match "STRIPE_PUBLISHABLE_KEY", error.message
  end

  test "test keys boot and live keys are ignored outside production" do
    assert_nothing_raised do
      StripeKeyGuard.ensure_test_keys!(
        { "STRIPE_SECRET_KEY" => "sk_test_secret", "STRIPE_PUBLISHABLE_KEY" => "pk_test_public" },
        production: true
      )
      StripeKeyGuard.ensure_test_keys!(
        { "STRIPE_SECRET_KEY" => "sk_live_secret", "STRIPE_PUBLISHABLE_KEY" => "pk_live_public" },
        production: false
      )
    end
  end
end
