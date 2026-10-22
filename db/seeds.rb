# Test databases must stay empty so regression tests own their fixtures.
unless Rails.env.test?
  DemoSeeds.run
  puts 'Demo projects created. Register your own account to explore; seeded accounts have random passwords.'
end
