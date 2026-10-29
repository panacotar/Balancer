module ApplicationHelper
  STRIPE_TEST_CARD_NOTICE = 'Test card: 4242 4242 4242 4242, any future expiry, any CVC, any postal code.'.freeze

  def stripe_test_card_notice
    STRIPE_TEST_CARD_NOTICE
  end
end
