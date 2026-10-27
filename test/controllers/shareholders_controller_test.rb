require 'test_helper'

class ShareholdersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @owner = create_user(email: 'holder@example.com', phone: '5550002222')
    @campaign = create_campaign_for(@owner, name: 'Holder Round')
    sign_in @owner
  end

  test 'does not create a shareholder when the checkout is unpaid' do
    order = create_order('cs_test_unpaid')
    stub_session('cs_test_unpaid', payment_status: 'unpaid', amount_total: order.amount_cents)

    assert_no_difference 'Shareholder.count' do
      get new_project_shareholder_path(@campaign.project), params: { session_id: order.checkout_session_id }
    end
    assert_redirected_to order_path(order)
    assert_equal 'pending', order.reload.state
  end

  test 'creates one shareholder for a paid checkout and ignores a repeat visit' do
    order = create_order('cs_test_paid')
    stub_session('cs_test_paid', payment_status: 'paid', amount_total: order.amount_cents)

    assert_difference 'Shareholder.count', 1 do
      get new_project_shareholder_path(@campaign.project), params: { session_id: order.checkout_session_id }
    end
    assert_redirected_to successfulpledge_path
    assert_equal 'paid', order.reload.state

    assert_no_difference 'Shareholder.count' do
      get new_project_shareholder_path(@campaign.project), params: { session_id: order.checkout_session_id }
    end
    assert_redirected_to successfulpledge_path
  end

  test 'no longer accepts a direct shareholder post' do
    post "/projects/#{@campaign.project.id}/shareholders", params: { pledge_amount: 10 }
    assert_response :not_found
  end

  private

  def create_order(session_id)
    order = Order.new(campaign: @campaign, user: @owner, state: 'pending', campaign_sku: 'sku', checkout_session_id: session_id)
    order.amount = 100
    order.save!
    order
  end

  def stub_session(session_id, payment_status:, amount_total:)
    stub_request(:get, "https://api.stripe.com/v1/checkout/sessions/#{session_id}").to_return(
      status: 200,
      headers: { 'Content-Type' => 'application/json' },
      body: {
        id: session_id,
        object: 'checkout.session',
        payment_status: payment_status,
        amount_total: amount_total,
        url: "https://checkout.stripe.com/c/pay/#{session_id}",
        livemode: false
      }.to_json
    )
  end
end
