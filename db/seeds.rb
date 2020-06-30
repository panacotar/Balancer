require 'faker'
  #Users
  #campaingn
  #transactions
  #projects
  #shareholders
Project.destroy_all
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

10.times do
Project.create(project_name: Faker::Company.name,
                category: Faker::Company.industry,
                vision: Faker::Lorem.paragraph,
                pitch: Faker::Lorem.paragraph,
                target: Faker::Team.name,
                user: User.all.sample)
end

puts "Projects: #{Project.all.count}"




