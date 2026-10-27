Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  config.cache_store = :memory_store, { size: 32.megabytes }
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?
  config.assets.compile = false
  config.active_storage.service = ENV['CLOUDINARY_URL'].present? ? :cloudinary : :local

  domain = ENV.fetch('DOMAIN', 'balancer.organicdarius.com')
  config.hosts = [domain]
  # Probe exceptions do not expose application data.
  config.host_authorization = { exclude: ->(request) { request.path == '/healthcheck' } }
  config.force_ssl = true
  config.ssl_options = { redirect: { exclude: ->(request) { request.path == '/healthcheck' } },
                         hsts: { subdomains: false, preload: false } }
  config.action_mailer.default_url_options = { host: domain, protocol: 'https' }
  config.action_controller.default_url_options = { host: domain, protocol: 'https' }

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_caching = false
  config.action_mailer.smtp_settings = {
    address: ENV['SMTP_ADDRESS'], port: Integer(ENV.fetch('SMTP_PORT', '587')),
    domain: ENV.fetch('SMTP_DOMAIN', domain), user_name: ENV['SMTP_USERNAME'],
    password: ENV['SMTP_PASSWORD'], authentication: :plain,
    enable_starttls: true, openssl_verify_mode: 'peer', open_timeout: 10, read_timeout: 10
  }

  config.log_level = :info
  config.log_tags = [:request_id]
  config.logger = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new($stdout))
  config.i18n.fallbacks = true
  config.active_support.deprecation = :log
  config.active_record.dump_schema_after_migration = false

  unless ENV['SECRET_KEY_BASE_DUMMY'].present?
    raise 'Set SECRET_KEY_BASE or SECRET_KEY_BASE_FILE (at least 64 characters).' if ENV['SECRET_KEY_BASE'].to_s.length < 64
  end
end
