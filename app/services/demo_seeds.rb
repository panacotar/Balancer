require 'securerandom'
require 'stringio'
require 'digest'
require 'yaml'

class DemoSeeds
  class Conflict < StandardError; end

  CATALOGUE = YAML.safe_load_file(Rails.root.join('db/demo_campaigns.yml'), symbolize_names: true).map(&:freeze).freeze
  BACKERS = ['Alice Moreira', 'Bruno Santos', 'Eva Ferreira'].freeze
  BACKING_WEIGHTS = [50, 30, 20].freeze
  DEMO_NOTICE = 'Illustrative Balancer demo: the team, funding, and plans are fictional; no real investment is offered.'.freeze

  def self.run
    new.run
  end

  def self.photo_path(entry)
    Rails.root.join('db/seeds/photos', "#{entry.fetch(:key)}.jpg")
  end

  def run
    ActiveRecord::Base.transaction do
      # Serialize seed runs as names/SKUs intentionally have no new schema constraints.
      ActiveRecord::Base.connection.execute('SELECT pg_advisory_xact_lock(721905260)')
      backers = BACKERS.each_with_index.map do |name, index|
        demo_user("demo-backer#{index + 1}@example.test", "demo-backer-#{index + 1}", name)
      end
      CATALOGUE.each { |entry| seed_campaign(entry, backers) }
    end
  end

  private

  def demo_user(email, phone, name, placeholder_name: nil)
    user = User.find_or_initialize_by(email: email)
    if user.persisted? && user.phone_number != phone
      raise Conflict, "Demo account #{email} conflicts with an existing account; no records were changed."
    end

    first_name, last_name = name.split(' ', 2)
    if user.new_record?
      user.assign_attributes(first_name: first_name, last_name: last_name,
                             password: SecureRandom.urlsafe_base64(24), address: 'Lisbon, Portugal',
                             date_of_birth: Date.new(1990, 1, 1), gender: 'others', phone_number: phone)
    elsif placeholder_name && user.first_name == placeholder_name && user.last_name == 'Founder'
      user.assign_attributes(first_name: first_name, last_name: last_name, address: 'Lisbon, Portugal')
    end
    user.save! if user.new_record? || user.changed?
    user
  end

  def seed_campaign(entry, backers)
    id = entry.fetch(:id)
    founder = demo_user("demo#{id}@example.test", "demo-#{id}", entry.fetch(:founder), placeholder_name: "Demo #{id}")
    project = unique_seed_record(founder.projects, :project_name, entry.fetch(:project_name), "Community project #{id}")
    project.user = founder
    campaign = unique_seed_record(project.campaigns, :name, entry.fetch(:name), "Community campaign #{id}")
    collision = Campaign.where(name: entry.fetch(:name)).where.not(id: campaign.id).exists?
    raise Conflict, "Campaign #{entry.fetch(:name).inspect} belongs to another record; no records were changed." if collision

    refresh_dates = campaign.new_record? || campaign.name == "Community campaign #{id}"
    project.assign_attributes(entry.slice(:project_name, :category, :vision, :target).merge(
      pitch: "#{entry.fetch(:pitch)} #{DEMO_NOTICE}", status: true
    ))
    attach_photo(project, entry)
    project.save!
    campaign.project = project

    if campaign.new_record?
      campaign.assign_attributes(entry.slice(:investment_goal, :equity))
      campaign.assign_attributes(name: entry.fetch(:name), description: entry.fetch(:description), status: true,
                                 start_date: entry.fetch(:started_days_ago).days.ago,
                                 end_date: entry.fetch(:ends_in_days).days.from_now)
      campaign.save!
    end
    campaign.with_lock do
      # Existing commitments retain the economics they were created against.
      unless campaign.orders.exists? || campaign.shareholders.exists?
        campaign.assign_attributes(entry.slice(:investment_goal, :equity))
      end
      campaign.assign_attributes(entry.slice(:name, :description).merge(status: true))
      if refresh_dates
        campaign.assign_attributes(start_date: entry.fetch(:started_days_ago).days.ago,
                                   end_date: entry.fetch(:ends_in_days).days.from_now)
      end
      campaign.save! if campaign.changed?
      seed_backing(campaign, entry, backers)
    end
  end

  def unique_seed_record(scope, attribute, name, placeholder)
    records = scope.where(attribute => [name, placeholder]).to_a
    if records.many?
      raise Conflict, "Ambiguous demo #{attribute}: found both #{name.inspect} and #{placeholder.inspect}; no records were changed."
    end
    records.first || scope.klass.new
  end

  def attach_photo(project, entry)
    if project.photo.attached?
      blob = project.photo.blob
      old_checksum = Digest::MD5.file(Rails.root.join('app/assets/images/bg_buswoman.jpg')).base64digest
      return unless blob.filename.to_s == 'demo-project.jpg' && blob.checksum == old_checksum
    end

    project.photo.attach(io: StringIO.new(File.binread(self.class.photo_path(entry))),
                         filename: "#{entry.fetch(:key)}.jpg", content_type: 'image/jpeg')
  end

  def seed_backing(campaign, entry, backers)
    target = campaign.investment_goal.to_d * entry.fetch(:funding_percent) / 100
    BACKING_WEIGHTS.each_with_index do |weight, index|
      sku = "demo-seed-#{entry.fetch(:key)}-backer-#{index + 1}"
      next if campaign.orders.exists?(campaign_sku: sku)

      amount = [target * weight / 100, campaign.available_pledge].min.round(2, BigDecimal::ROUND_DOWN)
      next unless amount.positive?

      # Synthetic demo receipts only: no Stripe session or provider interaction.
      order = campaign.orders.create!(user: backers.fetch(index), campaign_sku: sku, amount: amount, state: 'paid')
      order.create_shareholder!(user: order.user, campaign: campaign, amount: amount, status: 'Active',
                                percentage: campaign.equity.to_d * amount / campaign.investment_goal)
    end
  end
end
