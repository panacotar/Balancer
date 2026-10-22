require 'test_helper'

class StripeWebhooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @previous_secret = ENV['STRIPE_WEBHOOK_SECRET']
    ENV['STRIPE_WEBHOOK_SECRET'] = 'whsec_test_example'
    @order = create_order
  end

  teardown do
    ENV['STRIPE_WEBHOOK_SECRET'] = @previous_secret
  end

  def send_event(session: checkout_session(@order), type: 'checkout.session.completed', livemode: false,
                 signature_secret: ENV['STRIPE_WEBHOOK_SECRET'])
    payload = { id: 'evt_test_example', object: 'event', type: type, livemode: livemode,
                data: { object: session.to_hash } }.to_json
    timestamp = Time.now
    signature = Stripe::Webhook::Signature.compute_signature(timestamp, payload, signature_secret)
    header = Stripe::Webhook::Signature.generate_header(timestamp, signature)
    post '/stripe/webhook', params: payload,
         headers: { 'CONTENT_TYPE' => 'application/json', 'Stripe-Signature' => header }
  end

  test 'signed paid test session creates one exact pledge, even after retries' do
    create_order(user: @order.user) # Completion must not select the latest user order.
    assert_difference('Shareholder.count', 1) { send_event }
    assert_response :success
    assert_equal 'paid', @order.reload.state
    pledge = @order.shareholder
    assert_equal @order.user, pledge.user
    assert_equal @order.campaign, pledge.campaign
    assert_equal BigDecimal('25.50'), pledge.amount
    assert_equal BigDecimal('0.0255'), pledge.percentage
    assert_no_difference('Shareholder.count') { send_event }
    assert_response :success
  end

  test 'invalid signatures and unsigned requests cannot complete orders' do
    assert_no_difference('Shareholder.count') { send_event(signature_secret: 'incorrect-secret') }
    assert_response :bad_request
    post '/stripe/webhook', params: '{}', headers: { 'CONTENT_TYPE' => 'application/json' }
    assert_response :bad_request
    assert_equal 'pending', @order.reload.state
  end

  test 'signed tampered sessions, live events and unknown orders are rejected' do
    [{ amount_total: 1 }, { currency: 'usd' }, { client_reference_id: 'wrong' },
     { metadata: { order_id: 'wrong' } }, { metadata: nil }, { id: 'cs_test_unknown' }, { livemode: true },
     { mode: 'subscription' }].each do |attributes|
      assert_no_difference('Shareholder.count') { send_event(session: checkout_session(@order, **attributes)) }
      assert_response :bad_request
    end
    assert_no_difference('Shareholder.count') { send_event(livemode: true) }
    assert_response :bad_request
  end

  test 'a paid session beyond remaining capacity records no pledge and does not retry' do
    Shareholder.create!(user: create_user, campaign: @order.campaign, amount: @order.campaign.investment_goal,
                        percentage: @order.campaign.equity, status: 'Active')
    assert_no_difference('Shareholder.count') { send_event }
    assert_response :success
    assert_equal 'failed', @order.reload.state
    assert_no_difference('Shareholder.count') { send_event }
    assert_response :success
  end

  test 'unpaid, expired and unrelated events do not create pledges' do
    assert_no_difference('Shareholder.count') do
      send_event(session: checkout_session(@order, payment_status: 'unpaid'))
      assert_response :success
      send_event(session: checkout_session(@order, status: 'expired', payment_status: 'unpaid'), type: 'checkout.session.expired')
      assert_response :success
      send_event(type: 'payment_intent.payment_failed')
      assert_response :success
    end
    assert_equal 'pending', @order.reload.state
  end

  test 'webhook fails closed without a signing secret' do
    ENV.delete('STRIPE_WEBHOOK_SECRET')
    post '/stripe/webhook'
    assert_response :service_unavailable
  end
end
