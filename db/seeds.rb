require 'faker'
require 'open-uri'
  #Users
  #campaingn
  #transactions
  #projects
  #shareholders
Campaign.destroy_all
# Project.destroy_all
# User.destroy_all

# puts 'Creating Users'

# 10.times do
#   User.create(first_name: Faker::Name.first_name,
#              last_name: Faker::Name.last_name,
#              email: Faker::Internet.email,
#              password: '123123',
#              address: Faker::Address.city,
#              date_of_birth: Faker::Date.birthday(min_age: 18, max_age: 75),
#              gender: Faker::Gender.binary_type.downcase,
#              phone_number: Faker::PhoneNumber.cell_phone)
# end

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
  'https://images.unsplash.com/photo-1588119498215-e70577775a31?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=667&q=80',
  'https://images.unsplash.com/photo-1561503152-fda6a4423b86?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=750&q=80',
  'https://images.unsplash.com/photo-1571063769135-f7b6b742db4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=354&q=80',
  'https://images.unsplash.com/photo-1552256028-2c58c3cbfa7a?ixlib=rb-1.2.1&auto=format&fit=crop&w=334&q=80',
  'https://images.unsplash.com/photo-1553921895-a1b5b2500a17?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=334&q=80',
  'https://images.unsplash.com/photo-1541970540630-d459912c696f?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=750&q=80',
  'https://images.unsplash.com/photo-1551911729-aeb5b569c307?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=749&q=80',
  'https://images.unsplash.com/photo-1571781926291-c477ebfd024b?ixlib=rb-1.2.1&auto=format&fit=crop&w=334&q=80',
  'https://images.unsplash.com/photo-1570569962804-5377da5be035?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=524&q=80',
  'https://images.unsplash.com/photo-1564616836577-9bd4ece8c1f5?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=334&q=80',
  'https://images.unsplash.com/photo-1529390079861-591de354faf5?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=750&q=80',
  'https://images.unsplash.com/photo-1546074177-ffdda98d214f?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=667&q=80'
  ]

# puts 'Creating projects'
# projects_photos_url.each do |url|
#   pr = Project.new(project_name: Faker::Company.name,
#                  category: projects_categories.sample,
#                  vision: Faker::Lorem.paragraph,
#                  pitch: Faker::Lorem.paragraph,
#                  target: Faker::Team.name,
#                  user: User.all.sample)

#   file = URI.open(url)
#   pr.photo.attach(io: file, filename: 'nes.png', content_type: 'image/png')

#   puts "Creating #{pr.project_name}"
#   pr.save
# end

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


