# Be sure to restart your server when you modify this file.

Rails.application.config.content_security_policy do |policy|
  policy.default_src :self
  policy.base_uri :self
  policy.object_src :none
  policy.frame_src :self, 'https://js.stripe.com', 'https://checkout.stripe.com'
  # amCharts 4 builds some internals with eval. Inline styles are injected by
  # amCharts, AOS, and slick.
  policy.script_src :self, 'https://js.stripe.com', :unsafe_eval
  policy.style_src :self, :unsafe_inline, 'https://fonts.googleapis.com', 'https://cdn.jsdelivr.net'
  policy.font_src :self, :data, 'https://fonts.gstatic.com'
  policy.img_src :self, :data, 'https://res.cloudinary.com', 'https://images.unsplash.com'
  policy.connect_src :self
end

# Report-only until a browser pass confirms amCharts and the rest of the page
# do not need anything else. Switch this off once the console is clean.
Rails.application.config.content_security_policy_report_only = true
