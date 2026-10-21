ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'minitest/mock'
require 'webmock/minitest'
WebMock.disable_net_connect!(allow_localhost: true)

module DemoRecords
  def create_user(**attributes)
    User.create!({ first_name: 'Demo', last_name: 'Tester', address: 'Demo City',
                   date_of_birth: Date.new(1990, 1, 1), gender: 'others',
                   phone_number: SecureRandom.hex(8), email: "#{SecureRandom.hex(8)}@example.test",
                   password: 'test-password-only' }.merge(attributes))
  end

  def create_project(user: create_user, **attributes)
    Project.create!({ user: user, project_name: "Community #{SecureRandom.hex(4)}", category: 'Education',
                      vision: 'An inclusive community', pitch: 'Support our project', target: 'Everyone',
                      status: false }.merge(attributes))
  end

  def create_campaign(project: create_project, **attributes)
    Campaign.create!({ project: project, name: "Garden #{SecureRandom.hex(4)}", description: 'Community garden',
                       start_date: 1.day.ago, end_date: 30.days.from_now, investment_goal: 10_000,
                       equity: 10, status: false }.merge(attributes))
  end

  def create_order(user: create_user, campaign: create_campaign, **attributes)
    Order.create!({ user: user, campaign: campaign, amount: BigDecimal('25.50'), state: 'pending',
                    campaign_sku: SecureRandom.hex(8), checkout_session_id: "cs_test_#{SecureRandom.hex(8)}" }.merge(attributes))
  end

  def attach_photo(record)
    File.open(Rails.root.join('app/assets/images/bg_buswoman.jpg')) do |file|
      record.photo.attach(io: file, filename: 'demo.jpg', content_type: 'image/jpeg')
    end
  end

  def checkout_session(order, **attributes)
    Stripe::Checkout::Session.construct_from({ id: order.checkout_session_id, object: 'checkout.session',
      livemode: false, mode: 'payment', payment_status: 'paid', status: 'complete',
      client_reference_id: order.id.to_s, metadata: { order_id: order.id.to_s },
      amount_total: order.amount_cents, currency: 'eur', url: 'https://checkout.stripe.com/c/pay/cs_test_demo'
    }.merge(attributes))
  end

  def with_stripe_test_keys
    original = Rails.configuration.stripe
    Rails.configuration.stripe = { secret_key: 'sk_test_example', publishable_key: 'pk_test_example' }
    yield
  ensure
    Rails.configuration.stripe = original
  end
end

class ActiveSupport::TestCase
  include DemoRecords
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
