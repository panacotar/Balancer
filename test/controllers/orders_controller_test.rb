require 'test_helper'

class OrdersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @owner = create_user(email: 'owner@example.com')
    @campaign = create_campaign_for(@owner, name: 'Order Round')
    sign_in @owner
  end

  test 'rejects a pledge above the amount still available' do
    assert_no_difference 'Order.count' do
      post orders_path, params: { campaign_id: @campaign.id, pledge_amount: 1001 }
    end
    assert_redirected_to project_path(@campaign.project)
  end

  test 'rejects a pledge that is not a positive whole number' do
    assert_no_difference 'Order.count' do
      post orders_path, params: { campaign_id: @campaign.id, pledge_amount: '10.5' }
    end
    assert_redirected_to project_path(@campaign.project)
  end

  test 'reserves a pending checkout against later pledges' do
    stub_checkout('cs_test_hold')
    post orders_path, params: { campaign_id: @campaign.id, pledge_amount: 600 }

    assert_no_difference 'Order.count' do
      post orders_path, params: { campaign_id: @campaign.id, pledge_amount: 500 }
    end
    assert_redirected_to project_path(@campaign.project)
  end

  test 'creates a checkout session for an in-range pledge' do
    stub_checkout('cs_test_order')

    assert_difference 'Order.count', 1 do
      post orders_path, params: { campaign_id: @campaign.id, pledge_amount: 100 }
    end

    order = Order.last
    assert_equal 'pending', order.state
    assert_equal 'cs_test_order', order.checkout_session_id
    assert_equal 10_000, order.amount_cents
    assert_redirected_to new_order_payment_path(order)
    assert_requested :post, 'https://api.stripe.com/v1/checkout/sessions' do |request|
      assert_match(/\{CHECKOUT_SESSION_ID\}|%7BCHECKOUT_SESSION_ID%7D/, request.body)
    end
  end

  private

  def stub_checkout(session_id)
    stub_request(:post, 'https://api.stripe.com/v1/checkout/sessions').to_return(
      status: 200,
      headers: { 'Content-Type' => 'application/json' },
      body: {
        id: session_id,
        object: 'checkout.session',
        url: "https://checkout.stripe.com/c/pay/#{session_id}",
        payment_status: 'unpaid',
        livemode: false
      }.to_json
    )
  end
end
