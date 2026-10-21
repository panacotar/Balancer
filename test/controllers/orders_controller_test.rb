require 'test_helper'

class OrdersControllerTest < ActionDispatch::IntegrationTest
  test 'authorized test checkout sends modern parameters and preserves cents' do
    campaign = create_campaign
    sign_in create_user
    create_session = lambda do |params, options|
      assert_equal 'payment', params[:mode]
      assert_equal 2550, params[:line_items].first[:price_data][:unit_amount]
      assert_equal 'eur', params[:line_items].first[:price_data][:currency]
      order = Order.find(params[:client_reference_id])
      assert_equal order.id.to_s, params[:metadata][:order_id]
      assert_equal "demo-order-#{order.id}", options[:idempotency_key]
      assert_equal order_url(order), params[:success_url]
      Stripe::Checkout::Session.construct_from(id: 'cs_test_created', livemode: false)
    end
    with_stripe_test_keys do
      Stripe::Checkout::Session.stub(:create, create_session) do
        assert_difference('Order.count') { post orders_path, params: { campaign_id: campaign.id, pledge_amount: '25.50' } }
      end
    end
    assert_response :see_other
    assert_equal 'cs_test_created', Order.last.checkout_session_id
  end

  test 'unauthenticated requests cannot create an order or contact Stripe' do
    campaign = create_campaign
    assert_no_difference('Order.count') { post orders_path, params: { campaign_id: campaign.id, pledge_amount: '25' } }
    assert_redirected_to new_user_session_path
  end

  test 'invalid and excessive amounts never create orders' do
    campaign = create_campaign
    sign_in create_user
    %w[0 -1 25.555 10001 junk].each do |amount|
      assert_no_difference('Order.count') { post orders_path, params: { campaign_id: campaign.id, pledge_amount: amount } }
      assert_redirected_to project_path(campaign.project)
    end
  end

  test 'live credentials and live sessions cannot create a usable checkout' do
    campaign = create_campaign
    sign_in create_user
    with_stripe_test_keys do
      Rails.configuration.stripe[:secret_key] = 'sk_live_example'
      assert_no_difference('Order.count') { post orders_path, params: { campaign_id: campaign.id, pledge_amount: '25' } }
      assert_redirected_to project_path(campaign.project)
    end
    with_stripe_test_keys do
      Stripe::Checkout::Session.stub(:create, Stripe::Checkout::Session.construct_from(id: 'cs_live_bad', livemode: true)) do
        post orders_path, params: { campaign_id: campaign.id, pledge_amount: '25' }
      end
    end
    assert_equal 'failed', Order.last.state
    assert_nil Order.last.checkout_session_id
  end

  test 'Stripe failure leaves a failed order and creates no pledge' do
    campaign = create_campaign
    sign_in create_user
    with_stripe_test_keys do
      Stripe::Checkout::Session.stub(:create, ->(*) { raise Stripe::APIConnectionError, 'Unavailable' }) do
        assert_no_difference('Shareholder.count') { post orders_path, params: { campaign_id: campaign.id, pledge_amount: '25' } }
      end
    end
    assert_equal 'failed', Order.last.state
  end

  test 'order return and cancel pages cannot complete payment or expose another account order' do
    order = create_order
    sign_in order.user
    assert_no_difference('Shareholder.count') do
      get order_path(order)
      assert_response :success
      get order_path(order), params: { canceled: '1' }
      assert_response :success
    end
    assert_equal 'pending', order.reload.state
    sign_in create_user
    assert_raises(ActiveRecord::RecordNotFound) { get order_path(order) }
  end
end
