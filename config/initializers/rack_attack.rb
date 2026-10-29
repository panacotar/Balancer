Rack::Attack.throttle('logins/ip', limit: 5, period: 20.seconds) do |request|
  request.ip if request.post? && request.path == '/users/sign_in'
end

Rack::Attack.throttle('logins/email', limit: 5, period: 60.seconds) do |request|
  if request.post? && request.path == '/users/sign_in'
    request.params.dig('user', 'email').to_s.downcase.presence
  end
end

Rack::Attack.throttle('password-resets/ip', limit: 5, period: 60.seconds) do |request|
  request.ip if request.post? && request.path == '/users/password'
end

Rack::Attack.throttle('password-resets/email', limit: 5, period: 60.seconds) do |request|
  if request.post? && request.path == '/users/password'
    request.params.dig('user', 'email').to_s.downcase.presence
  end
end
