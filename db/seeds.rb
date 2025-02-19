require 'faker'
require 'open-uri'
# Users
# Campaign
# Transactions
# Projects
# Shareholders

puts 'Creating Users'

10.times do
  User.create(first_name: Faker::Name.first_name,
             last_name: Faker::Name.last_name,
             email: Faker::Internet.email,
             password: '123123',
             address: Faker::Address.city,
             date_of_birth: Faker::Date.birthday(min_age: 18, max_age: 75),
             gender: Faker::Gender.binary_type.downcase,
             phone_number: Faker::PhoneNumber.cell_phone)
end

puts "Users: #{User.all.count}"



projects_categories = [
  'Arts & crafts',
  'Beauty and fragrances',
  'Books and magazines',
  'Clothing, accessories',
  'Computers, accessories',
  'Education',
  'Entertainment and media',
  'Food retail and service',
  'Sports and outdoors',
  'Travel',
  'Services',
  'Others'
]

projects_photos_url = [
  'https://images.unsplash.com/photo-1562157646-4303261af91e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=1100&q=80',
  'https://images.unsplash.com/photo-1573407947625-124549936954?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=1100&q=80',
  'https://images.unsplash.com/photo-1554244933-d876deb6b2ff?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=1100&q=80',
  'https://images.unsplash.com/photo-1592106680408-e7e63efbc7ba?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=1100&q=80',
  'https://images.unsplash.com/photo-1569385210018-127685230669?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=1100&q=80',
  'https://images.unsplash.com/photo-1521510186458-bbbda7aef46b?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=1100&q=80',
  'https://images.unsplash.com/flagged/photo-1576784188474-db03a2d80fca?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=1100&q=80',
  'https://images.unsplash.com/photo-1584060713648-8f1cc8fc1e5a?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=1100&q=80',
  'https://images.unsplash.com/photo-1564974944378-7f6b56fea4a2?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=1100&q=80',
  'https://images.unsplash.com/photo-1588959570984-9f1e0e9a91a6?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=1100&q=80',
  'https://images.unsplash.com/photo-1571115355423-1d318bd95e22?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=1100&q=80'
]

puts 'Creating projects'
projects_photos_url.each do |url|
  pr = Project.new(project_name: Faker::Company.name,
                 category: projects_categories.sample,
                 vision: Faker::Lorem.paragraph,
                 pitch: Faker::Lorem.paragraph,
                 target: Faker::Team.name,
                 user: User.all.sample)

  puts "Getting photo at #{url} for the #{pr.project_name}"
  file = URI.open(url)
  pr.photo.attach(io: file, filename: 'nes.png', content_type: 'image/png')

  puts "Creating #{pr.project_name}"
  pr.save
end

puts "Projects: #{Project.all.count}"

projects_arr = Project.all

campaigns_names = [
  'The Briiv Air Filter',
  'AusAir',
  'Reinventing The Lightest Luxury Smart Glasses',
  'Atelier Riforma',
  'KEFIRKO - VEGGIE FERMENTER',
  'Hitch',
  'Prepared, Protected and always Up-to-Date!',
  'Rich Recovery: Brain Power In a Bottle',
  'AMX Electric Bike: The e-bike for cities',
  'QuenchSea',
  'V-Tex'
  ]

campaigns_descriptions = [
  "Unlock The Power Of Plants. The world's most sustainable air purifier.",
  'Next Gen Filtration Mask With Botanicals. Highly breathable, and reusable.',
  'Combining the finest materials with the most advanced technology',
  'We use creativity to reduce the environmental impact of fashion.',
  'Ferment mixed veggies, kimchi, or any other vegetable in your kitchen!',
  'The water bottle with a removable cup hidden inside. Go zero waste.',
  'Qurelife, Much More than just First Aid! - invented in Switzerland',
  'A 3 oz, natural drink to boost cognition, physical performance, and immunity.',
  'The AMX is a lightweight, high-performance, urban electric bike.',
  'The World’s Only Low-Cost Portable Seawater Desalination Device.',
  'Nanotech-12 Waterproof Knit Shoe. Mix of cozy slippers & waterproof boots'

  ]

counter = 0
puts 'Creating campaigns'
projects_arr.each do |project|
  campaign = Campaign.new(name: campaigns_names[counter],
                  start_date: Faker::Date.backward(days: 2),
                  end_date: Faker::Date.forward(days: 28),
                  description: campaigns_descriptions[counter],
                  project: project,
                  equity: Faker::Number.between(from: 1, to: 15),
                  investment_goal: Faker::Number.number(digits: 5))
  counter += 1

  puts "Creating campaign: #{campaign.name}"
  campaign.save
end
puts "Campaigns: #{Campaign.all.count}"


puts 'Creating Shareholder'
30.times do

  campaign = Campaign.all.sample
  amount_pledged = rand(1..campaign.investment_goal)

  percent = ( amount_pledged / campaign.investment_goal ) * 100

  new_shareholder = Shareholder.new(
                    amount: amount_pledged,
                    percentage: percent,
                    status: "Active",
                    user: User.all.sample,
                    campaign: campaign)
  puts "New pledge: #{new_shareholder.amount} € on #{new_shareholder.campaign.name}"
  new_shareholder.save

  order = Order.new(
          campaign: campaign,
          campaign_sku: campaign.name.gsub(' ', '_') + rand(1..9999).to_s,
          amount: new_shareholder.amount,
          state: 'paid',
          user: User.all.sample)

  puts "Creating receipt #{order.campaign_sku} for #{order.user.first_name}"
  order.save
end

puts "Shareholder: #{Shareholder.all.count}"

puts "Finished"
