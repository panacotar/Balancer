require "test_helper"
require "open3"
require "socket"
require "timeout"

class ProductionMailerTest < ActiveSupport::TestCase
  test "production refuses SMTP authentication and delivery without STARTTLS" do
    server = TCPServer.new("127.0.0.1", 0)
    commands = []
    worker = Thread.new do
      socket = server.accept
      socket.puts "220 local-test ESMTP\r"
      while (line = socket.gets)
        commands << line
        case line
        when /\AEHLO/
          socket.write "250-local-test\r\n250 AUTH PLAIN\r\n"
        when /\AQUIT/
          socket.write "221 bye\r\n"
          break
        else
          # Stop an insecure client before it can send a message.
          socket.write "535 TLS required\r\n"
        end
      end
    ensure
      socket&.close
    end

    # Load the actual production settings in a separate process, keeping this
    # test process's Rails configuration and credentials untouched.
    env = {
      "RAILS_ENV" => "production", "DOMAIN" => "example.invalid",
      "SECRET_KEY_BASE_DUMMY" => "1", "SENTRY_DSN" => "",
      "STRIPE_SECRET_KEY" => "sk_test_placeholder",
      "STRIPE_PUBLISHABLE_KEY" => "pk_test_placeholder",
      "SMTP_ADDRESS" => "127.0.0.1", "SMTP_PORT" => server.addr[1].to_s,
      "SMTP_USERNAME" => "synthetic-user", "SMTP_PASSWORD" => "synthetic-password",
      "MAIL_FROM" => "sender@example.invalid"
    }
    script = <<~RUBY
      require_relative "config/environment"
      message = Mail.new(from: "sender@example.invalid", to: "recipient@example.invalid", body: "Synthetic reset link")
      message.delivery_method(:smtp, Rails.application.config.action_mailer.smtp_settings)
      begin
        message.deliver!
        abort "SMTP delivery unexpectedly succeeded without TLS"
      rescue Net::SMTPUnsupportedCommand
        puts "STARTTLS required"
      end
    RUBY
    stdout, stderr, status = Timeout.timeout(30) do
      Open3.capture3(env, RbConfig.ruby, "-e", script, chdir: Rails.root)
    end

    assert status.success?, "Production mail check failed: #{stderr}"
    assert_includes stdout, "STARTTLS required"
    assert worker.join(5), "SMTP connection did not close"
    assert commands.any? { |line| line.start_with?("EHLO") }
    refute commands.any? { |line| line.match?(/\A(?:AUTH|MAIL FROM|RCPT TO|DATA)/) }, "Sent credentials or mail before TLS"
  ensure
    worker&.kill
    worker&.join
    server&.close
  end
end
