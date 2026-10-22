require 'test_helper'

class PaymentsControllerTest < ActionDispatch::IntegrationTest
  test 'payment summary links to verified hosted test checkout' do
    order = create_order
    sign_in order.user
    with_stripe_test_keys do
      Stripe::Checkout::Session.stub(:retrieve, checkout_session(order, status: 'open', payment_status: 'unpaid')) do
        get new_order_payment_path(order)
      end
    end
    assert_response :success
    assert_select 'a[href^="https://checkout.stripe.com/"]', text: 'Continue to Stripe test checkout'
    assert_select 'script[src="https://js.stripe.com/v3/"]', count: 0
  end

  test 'another user cannot view payment details' do
    order = create_order
    sign_in create_user
    assert_raises(ActiveRecord::RecordNotFound) { get new_order_payment_path(order) }
  end

  test 'live, mismatched and unsafe checkout URLs are rejected' do
    order = create_order
    sign_in order.user
    [{ livemode: true }, { client_reference_id: 'wrong' }, { amount_total: 1 },
     { url: 'https://evil.example/' }, { status: 'expired' }].each do |attributes|
      with_stripe_test_keys do
        Stripe::Checkout::Session.stub(:retrieve, checkout_session(order, status: 'open', **attributes)) do
          get new_order_payment_path(order)
        end
      end
      assert_redirected_to order_path(order)
    end
  end
end
