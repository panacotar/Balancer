require 'securerandom'
require 'stringio'

class DemoSeeds
  def self.run
    ActiveRecord::Base.transaction do
      6.times do |index|
        user = User.find_or_initialize_by(email: "demo#{index + 1}@example.test")
        if user.new_record?
          user.assign_attributes(first_name: "Demo #{index + 1}", last_name: 'Founder',
                                 password: SecureRandom.urlsafe_base64(24), address: 'Demo City',
                                 date_of_birth: Date.new(1990, 1, 1), gender: 'others',
                                 phone_number: "demo-#{index + 1}")
          user.save!
        end
        project = user.projects.find_or_initialize_by(project_name: "Community project #{index + 1}")
        project.assign_attributes(category: 'Education', vision: 'A more inclusive community.',
                                  pitch: 'Support this example community project.', target: 'Our community', status: true)
        unless project.photo.attached?
          project.photo.attach(io: StringIO.new(File.binread(Rails.root.join('app/assets/images/bg_buswoman.jpg'))),
                               filename: 'demo-project.jpg', content_type: 'image/jpeg')
        end
        project.save!
        campaign = project.campaigns.find_or_initialize_by(name: "Community campaign #{index + 1}")
        campaign.update!(description: 'Demo funding for an inclusive community.', start_date: 1.day.ago,
                         end_date: 30.days.from_now, equity: 10, investment_goal: 10_000, status: true)
      end
    end
  end
end
