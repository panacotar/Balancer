class ApplicationMailer < ActionMailer::Base
  default from: ENV["MAIL_FROM"].presence || "support@balancer.com"
  layout 'mailer'
end
