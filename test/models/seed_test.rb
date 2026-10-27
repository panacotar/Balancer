require 'test_helper'

class SeedTest < ActiveSupport::TestCase
  test 'database preparation skips demo seeds in the test environment' do
    assert_no_difference(counts) { load Rails.root.join('db/seeds.rb') }
  end

  test 'catalogue restores eleven complete campaigns with local images and consistent demo backing' do
    DemoSeeds.run

    assert_equal [14, 11, 11, 33, 33, 11, 11],
                 [User, Project, Campaign, Order, Shareholder, ActiveStorage::Attachment, ActiveStorage::Blob].map(&:count)
    assert_equal 11, DemoSeeds::CATALOGUE.size
    assert_equal 11, DemoSeeds::CATALOGUE.pluck(:key).uniq.size
    assert_operator Project.distinct.count(:category), :>=, 6
    assert_equal 11, Project.all.map { |project| project.photo.blob.checksum }.uniq.size
    assert_equal 'The Briiv Air Filter', campaign_for(1).name
    assert_equal 'V-Tex', campaign_for(11).name

    DemoSeeds::CATALOGUE.each do |entry|
      campaign = campaign_for(entry.fetch(:id))
      project = campaign.project
      assert campaign.valid?, campaign.errors.full_messages.join(', ')
      assert project.valid?, project.errors.full_messages.join(', ')
      assert campaign.active?
      assert project.active?
      assert_operator campaign.description.length, :<=, 80
      assert_operator campaign.start_date, :<, Time.current
      assert_operator campaign.end_date, :>, Time.current
      assert_includes project.pitch, DemoSeeds::DEMO_NOTICE
      assert_equal File.binread(DemoSeeds.photo_path(entry)), project.photo.download
      assert_equal 'test', project.photo.blob.service_name
      assert_equal entry.fetch(:funding_percent), campaign.percent
      assert_equal entry.fetch(:investment_goal).to_d * entry.fetch(:funding_percent) / 100,
                   campaign.shareholders.sum(:amount)
      assert_equal [50, 30, 20], campaign.orders.order(:id).map { |order| (order.amount.to_d / campaign.shareholders.sum(:amount) * 100).to_i }
      campaign.orders.each do |order|
        assert_equal 'paid', order.state
        assert_nil order.checkout_session_id
        assert_match(/\Ademo-seed-/, order.campaign_sku)
        pledge = order.shareholder
        assert_equal order.user, pledge.user
        assert_equal campaign, pledge.campaign
        assert_equal order.amount.to_d, pledge.amount
        assert_equal 'Active', pledge.status
        assert_equal (campaign.equity.to_d * pledge.amount / campaign.investment_goal).round(6), pledge.percentage
      end
    end
  end

  test 'reruns preserve dates passwords attachments and backing without any new records' do
    DemoSeeds.run
    before = database_snapshot

    travel 7.days do
      assert_no_difference(counts) { DemoSeeds.run }
    end

    assert_equal before, database_snapshot
  end

  test 'each new demo account receives a distinct random password and existing passwords are preserved' do
    passwords = []
    generator = SecureRandom.method(:urlsafe_base64)
    SecureRandom.stub(:urlsafe_base64, ->(length) { passwords << generator.call(length); passwords.last }) do
      DemoSeeds.run
    end

    assert_equal 14, passwords.uniq.size
    User.order(:id).zip(passwords).each do |user, password|
      assert user.valid_password?(password)
      assert_not user.valid_password?('123123')
    end
    before = User.order(:id).pluck(:encrypted_password)
    DemoSeeds.run
    assert_equal before, User.order(:id).pluck(:encrypted_password)
  end

  test 'six placeholders refresh in place preserving financial records custom photos and unrelated data' do
    placeholders = (1..6).map { |id| create_placeholder(id) }
    custom_project = placeholders[1].project
    custom_project.photo.attach(io: StringIO.new(File.binread(DemoSeeds.photo_path(DemoSeeds::CATALOGUE.last))),
                                filename: 'demo-project.jpg', content_type: 'image/jpeg')
    custom_blob_id = custom_project.photo.blob.id
    first = placeholders.first
    first.update!(equity: 7)
    paid = create_order(campaign: first, amount: BigDecimal('125.50'), state: 'paid')
    pledge = paid.create_shareholder!(user: paid.user, campaign: first, amount: paid.amount.to_d,
                                      percentage: BigDecimal('0.087850'), status: 'Active')
    pending = create_order(campaign: placeholders[1], amount: BigDecimal('9000'))
    unrelated = create_campaign
    unrelated_attributes = [unrelated.attributes, unrelated.project.attributes, unrelated.project.user.attributes]
    old_ids = placeholders.map { |campaign| [campaign.id, campaign.project_id, campaign.project.user_id] }
    payment_attributes = [paid.attributes, pledge.attributes, pending.attributes]

    assert_difference(['Project.count', 'Campaign.count'], 5) { DemoSeeds.run }

    placeholders.each_with_index do |campaign, index|
      refreshed = campaign_for(index + 1)
      assert_equal old_ids[index], [refreshed.id, refreshed.project_id, refreshed.project.user_id]
      assert_operator refreshed.end_date, :>, Time.current
      assert_equal DemoSeeds::CATALOGUE[index].fetch(:founder), "#{refreshed.project.user.first_name} #{refreshed.project.user.last_name}"
    end
    assert_equal [10_000, 7], [first.reload.investment_goal, first.equity]
    assert_equal [10_000, 10], [placeholders[1].reload.investment_goal, placeholders[1].equity]
    assert_equal custom_blob_id, custom_project.reload.photo.blob.id
    assert_equal 'briiv.jpg', first.project.photo.blob.filename.to_s
    assert_equal payment_attributes, [paid.reload.attributes, pledge.reload.attributes, pending.reload.attributes]
    assert_equal unrelated_attributes, [unrelated.reload.attributes, unrelated.project.reload.attributes, unrelated.project.user.reload.attributes]
    assert_not Campaign.where('name LIKE ?', 'Community campaign %').exists?
    assert_no_difference(counts) { DemoSeeds.run }
  end

  test 'sample backing respects confirmed capacity pending reservations and cent precision' do
    campaign = create_placeholder(1)
    paid = create_order(campaign: campaign, state: 'paid', amount: BigDecimal('2000'))
    paid.create_shareholder!(campaign: campaign, user: paid.user, amount: paid.amount.to_d, percentage: 2, status: 'Active')
    pending = create_order(campaign: campaign, amount: BigDecimal('7999.99'))
    full = create_placeholder(2)
    create_order(campaign: full, amount: BigDecimal('10000'))

    DemoSeeds.run

    assert_equal BigDecimal('2000.01'), campaign.shareholders.sum(:amount)
    assert_equal 1, campaign.orders.where('campaign_sku LIKE ?', 'demo-seed-%').count
    assert_equal 1, campaign.orders.find_by!(campaign_sku: 'demo-seed-briiv-backer-1').amount_cents
    assert_equal 0, campaign.available_pledge
    assert_equal 'pending', pending.reload.state
    assert_empty full.shareholders
    assert_empty full.orders.where('campaign_sku LIKE ?', 'demo-seed-%')
    assert_no_difference(counts) { DemoSeeds.run }
  end

  test 'a conflicting campaign name rolls back the entire seed refresh' do
    placeholder = create_placeholder(1)
    create_campaign(name: DemoSeeds::CATALOGUE.last.fetch(:name))
    before = database_snapshot

    error = assert_raises(DemoSeeds::Conflict) { DemoSeeds.run }

    assert_includes error.message, 'V-Tex'
    assert_equal before, database_snapshot
    assert_equal 'Community campaign 1', placeholder.reload.name
    assert_equal 'demo-project.jpg', placeholder.project.photo.blob.filename.to_s
  end

  test 'reserved demo accounts are not adopted from unrelated users' do
    create_user(email: 'demo1@example.test')
    before = database_snapshot

    assert_raises(DemoSeeds::Conflict) { DemoSeeds.run }

    assert_equal before, database_snapshot
  end

  test 'ambiguous placeholder and catalogue projects are reported without modifying data' do
    placeholder = create_placeholder(1)
    create_project(user: placeholder.project.user, project_name: DemoSeeds::CATALOGUE.first.fetch(:project_name))
    before = database_snapshot

    error = assert_raises(DemoSeeds::Conflict) { DemoSeeds.run }

    assert_includes error.message, 'Ambiguous'
    assert_equal before, database_snapshot
  end

  private

  def counts
    %w[User.count Project.count Campaign.count Order.count Shareholder.count ActiveStorage::Attachment.count ActiveStorage::Blob.count]
  end

  def database_snapshot
    [User, Project, Campaign, Order, Shareholder, ActiveStorage::Attachment, ActiveStorage::Blob].map do |model|
      model.order(:id).map(&:attributes)
    end
  end

  def campaign_for(id)
    User.find_by!(email: "demo#{id}@example.test").campaigns.sole
  end

  def create_placeholder(id)
    user = create_user(email: "demo#{id}@example.test", phone_number: "demo-#{id}",
                       first_name: "Demo #{id}", last_name: 'Founder')
    project = create_project(user: user, project_name: "Community project #{id}")
    project.photo.attach(io: StringIO.new(File.binread(Rails.root.join('app/assets/images/bg_buswoman.jpg'))),
                         filename: 'demo-project.jpg', content_type: 'image/jpeg')
    create_campaign(project: project, name: "Community campaign #{id}", status: true,
                    start_date: 100.days.ago, end_date: 50.days.ago)
  end
end
