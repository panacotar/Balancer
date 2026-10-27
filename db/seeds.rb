# Test databases must stay empty so regression tests own their fixtures.
unless Rails.env.test?
  DemoSeeds.run
  puts "#{DemoSeeds::CATALOGUE.size} historical demo campaigns refreshed with local photos and sample backing."
  puts 'All teams and funding activity are illustrative; no real investment or Stripe payment occurred.'
  puts 'Register your own account to explore; seeded accounts have random passwords.'
end
