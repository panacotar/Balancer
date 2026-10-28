class Campaign < ApplicationRecord
  belongs_to :project
  has_many :shareholders, dependent: :destroy
  has_many :orders
  has_one_attached :photo

  CHECKOUT_HOLD = 24.hours

  include PgSearch::Model
  pg_search_scope :search_by_name_and_description,
                  against: %i[name description],
                  using: {
                    tsearch: { prefix: true } # <-- now `superman batm` will return something!
                  }

  validates :name, presence: true, uniqueness: true
  validates :description, length: { maximum: 80 }
  validates :investment_goal, numericality: { only_integer: true, greater_than: 0 }, allow_blank: true
  validates :equity, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 100 }, allow_blank: true

  with_options if: :active? do
    validates :start_date, presence: true
    validates :end_date, presence: true
    validates :description, presence: true
    validates :amount, presence: true
    validates :percentage, presence: true
    validates :photo, presence: { message: "a photo must be uploaded, please" }
  end

  monetize :price_cents

  def active?
    status
  end

  def release_expired_checkouts!
    orders.where(state: 'pending').where(created_at: ..CHECKOUT_HOLD.ago).update_all(state: 'failed', updated_at: Time.current)
  end

  def available_pledge
    confirmed = shareholders.sum(:amount).to_d
    held = orders.where(state: 'pending').where('created_at > ?', CHECKOUT_HOLD.ago).sum(:amount_cents).to_d / 100
    investment_goal.to_d - confirmed - held
  end

  def percent
    pledged_total = 0
    shareholders.each do |sh|
      pledged_total += sh.amount
    end
    ((pledged_total / investment_goal) * 100).to_i
  end
end
