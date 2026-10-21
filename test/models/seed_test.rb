require 'test_helper'

class SeedTest < ActiveSupport::TestCase
  test 'database preparation skips demo seeds in the test environment' do
    assert_no_difference(['User.count', 'Project.count', 'Campaign.count']) { load Rails.root.join('db/seeds.rb') }
  end

  test 'demo seeding is repeatable and uses local bundled images and unique passwords' do
    assert_difference('Project.count', 6) { DemoSeeds.run }
    assert_no_difference(['User.count', 'Project.count', 'Campaign.count']) { DemoSeeds.run }
    users = User.where('email LIKE ?', 'demo%@example.test')
    assert_equal 6, users.count
    users.each { |user| assert_not user.valid_password?('123123') }
    assert_equal 6, Project.joins(:photo_attachment).where(user: users).count
    assert_empty Order.all
  end
end
