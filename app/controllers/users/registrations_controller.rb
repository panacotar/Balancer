class Users::RegistrationsController < Devise::RegistrationsController
  rate_limit to: 5, within: 1.hour, only: :create,
             store: AuthenticationRateLimits::STORE, with: -> { head :too_many_requests }
end
