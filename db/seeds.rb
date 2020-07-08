require 'faker'
require 'open-uri'
  #Users
  #campaingn
  #transactions
  #projects
  #shareholders
Campaign.destroy_all
Project.destroy_all
Order.destroy_all
User.destroy_all


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

  file = URI.open(url)
  pr.photo.attach(io: file, filename: 'nes.png', content_type: 'image/png')

  puts "Creating #{pr.project_name}"
  pr.save
end

puts "Projects: #{Project.all.count}"

projects_arr = Project.all

puts 'Creating campaigns'
projects_arr.each do |project|
  campaign = Campaign.new(name: Faker::Marketing.buzzwords,
                  start_date: Faker::Date.backward(days: 2),
                  end_date: Faker::Date.forward(days: 28),
                  description: Faker::Lorem.sentence(word_count: 8),
                  project: project,
                  percentage: Faker::Number.between(from: 1, to: 10),
                  amount: Faker::Number.number(digits: 6))

  puts "Creating campaign: #{campaign.name}"
  campaign.save
end

puts "Campaigns: #{Campaign.all.count}"


