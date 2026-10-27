# Read before Rails config so credentials never need to be baked into an image.
module RuntimeSecrets
  NAMES = %w[SECRET_KEY_BASE BALANCER_DATABASE_PASSWORD SMTP_PASSWORD
             STRIPE_SECRET_KEY STRIPE_PUBLISHABLE_KEY STRIPE_WEBHOOK_SECRET
             CLOUDINARY_URL SENTRY_DSN].freeze

  def self.load!(env = ENV)
    NAMES.each do |name|
      next if env["#{name}_FILE"].to_s.empty?

      value = File.read(env.fetch("#{name}_FILE")).strip
      env[name] = value unless value.empty?
    end
  end
end
