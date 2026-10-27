class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch('MAIL_FROM', 'demo@example.test') }
  layout 'mailer'
end
