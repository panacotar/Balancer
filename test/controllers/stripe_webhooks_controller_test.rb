require 'test_helper'

class StripeWebhooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = create_user(email: 'webhook@example.com', phone: '5550007777')
    @campaign = create_campaign_for(@owner, name: 'Webhook Round')
    @order = Order.new(campaign: @campaign, user: @owner, state: 'pending', campaign_sku: 'sku', checkout_session_id: 'cs_test_hook')
    @order.amount = 100
    @order.save!
    ENV['STRIPE_WEBHOOK_SECRET'] = 'whsec_test'
  end

  test 'creates a shareholder from a signed checkout completion and ignores a repeat' do
    assert_difference 'Shareholder.count', 1 do
      post '/stripe/webhook', params: event_payload, headers: stripe_headers(event_payload)
    end
    assert_response :ok
    assert_equal 'paid', @order.reload.state

    assert_no_difference 'Shareholder.count' do
      post '/stripe/webhook', params: event_payload, headers: stripe_headers(event_payload)
    end
    assert_response :ok
  end

  test 'rejects a webhook with a bad signature' do
    post '/stripe/webhook', params: event_payload, headers: { 'HTTP_STRIPE_SIGNATURE' => 't=1,v1=bad' }
    assert_response :bad_request
    assert_equal 'pending', @order.reload.state
  end

  private

  def event_payload
    {
      id: 'evt_test_hook',
      object: 'event',
      type: 'checkout.session.completed',
      data: {
        object: {
          id: 'cs_test_hook',
          object: 'checkout.session',
          payment_status: 'paid',
          amount_total: @order.amount_cents,
          payment_intent: nil
        }
      }
    }.to_json
  end

  def stripe_headers(payload)
    timestamp = Time.now
    signature = Stripe::Webhook::Signature.compute_signature(timestamp, payload, ENV['STRIPE_WEBHOOK_SECRET'])
    { 'HTTP_STRIPE_SIGNATURE' => Stripe::Webhook::Signature.generate_header(timestamp, signature) }
  end
end
