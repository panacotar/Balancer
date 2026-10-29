require 'test_helper'

class PaymentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @owner = create_user(email: 'payer@example.com')
    @campaign = create_campaign_for(@owner, name: 'Pay Round')
    sign_in @owner
  end

  test 'shows the Stripe test card on the checkout page' do
    order = Order.new(
      campaign: @campaign,
      user: @owner,
      state: 'pending',
      campaign_sku: 'sku',
      checkout_session_id: 'cs_test_pay'
    )
    order.amount = 100
    order.save!

    stub_request(:get, 'https://api.stripe.com/v1/checkout/sessions/cs_test_pay').to_return(
      status: 200,
      headers: { 'Content-Type' => 'application/json' },
      body: {
        id: 'cs_test_pay',
        object: 'checkout.session',
        url: 'https://checkout.stripe.com/c/pay/cs_test_pay',
        payment_status: 'unpaid'
      }.to_json
    )

    get new_order_payment_path(order)

    assert_response :success
    assert_match ApplicationHelper::STRIPE_TEST_CARD_NOTICE, response.body
  end
end
