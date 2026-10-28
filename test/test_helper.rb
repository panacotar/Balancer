ENV['RAILS_ENV'] ||= 'test'
ENV['STRIPE_SECRET_KEY'] ||= 'sk_test_placeholder'
ENV['STRIPE_PUBLISHABLE_KEY'] ||= 'pk_test_placeholder'

require_relative '../config/environment'
require 'rails/test_help'
require 'webmock/minitest'

WebMock.disable_net_connect!(allow_localhost: true)

class ActiveSupport::TestCase
  # Stripe stubs are process-wide, so keep the suite in one worker.
  parallelize(workers: 1)

  fixtures :all

  def create_user(email:)
    User.create!(
      email: email,
      password: 'password123',
      first_name: 'Ada',
      last_name: 'Lovelace',
      gender: 'female'
    )
  end

  def create_campaign_for(owner, name:)
    project = Project.create!(project_name: name, user: owner, status: false)
    Campaign.create!(
      name: name,
      description: 'A short description',
      project: project,
      investment_goal: 1_000,
      equity: 10,
      status: false
    )
  end
end
