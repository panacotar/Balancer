class Users::SessionsController < Devise::SessionsController
  rate_limit to: 10, within: 3.minutes, only: :create,
             store: AuthenticationRateLimits::STORE, with: -> { head :too_many_requests }
end
