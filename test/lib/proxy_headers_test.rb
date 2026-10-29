require "test_helper"

class ProxyHeadersTest < ActiveSupport::TestCase
  test "forged Forwarded headers cannot bypass IP limits across login accounts" do
    assert_ip_throttled("/users/sign_in")
  end

  test "forged Forwarded headers cannot bypass IP limits across password resets" do
    assert_ip_throttled("/users/password")
  end

  private

  def assert_ip_throttled(path)
    app = Rack::Attack.new(->(_env) { [200, {}, ["ok"]] })
    original_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

    travel_to Time.utc(2026, 1, 1) do
      statuses = 6.times.map do |index|
        env = Rack::MockRequest.env_for(path, method: "POST", input: "user[email]=person#{index}%40example.invalid")
        env.merge!(
          "CONTENT_TYPE" => "application/x-www-form-urlencoded",
          "REMOTE_ADDR" => "172.18.0.3",
          "HTTP_X_FORWARDED_FOR" => "198.51.100.7",
          "HTTP_FORWARDED" => "for=203.0.113.#{index + 1}"
        )
        app.call(env).first
      end

      assert_equal [200, 200, 200, 200, 200, 429], statuses
    end
  ensure
    Rack::Attack.cache.store = original_store
  end
end
