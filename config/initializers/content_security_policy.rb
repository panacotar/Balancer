Rails.application.config.content_security_policy do |policy|
  policy.default_src :self
  policy.script_src :self
  # Bootstrap, AOS, amCharts and existing views set inline styles.
  policy.style_src :self, :unsafe_inline, 'https://fonts.googleapis.com'
  policy.img_src :self, :data, :blob, 'https://images.unsplash.com', 'https://res.cloudinary.com'
  policy.font_src :self, :data, 'https://fonts.gstatic.com'
  policy.connect_src :self
  policy.object_src :none
  policy.base_uri :self
  policy.form_action :self
  policy.frame_ancestors :self
end
