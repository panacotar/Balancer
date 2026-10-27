class Users::PasswordsController < Devise::PasswordsController
  rate_limit to: 5, within: 15.minutes, only: :create,
             store: AuthenticationRateLimits::STORE, with: -> { head :too_many_requests }
end
