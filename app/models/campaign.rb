class Campaign < ApplicationRecord
  include ValidatedPhoto
  belongs_to :project
  has_many :shareholders, dependent: :destroy
  has_many :orders
  has_one_attached :photo

  include PgSearch::Model
  pg_search_scope :search_by_name_and_description,
                  against: %i[name description],
                  using: {
                    tsearch: { prefix: true } # <-- now `superman batm` will return something!
                  }

  validates :name, presence: true, uniqueness: true
  validates :description, length: { maximum: 80 }

  with_options if: :active? do
    validates :start_date, presence: true
    validates :end_date, presence: true
    validates :description, presence: true
  end

  validates :investment_goal, numericality: { greater_than: 0 }
  validates :equity, numericality: { greater_than: 0, less_than_or_equal_to: 100 }

  monetize :price_cents

  def active?
    status
  end

  def remaining_pledge
    [investment_goal.to_d - confirmed_pledge_amount, 0.to_d].max
  end

  # Room left for a new checkout. Pending sessions reserve capacity; confirmed pledges are shareholders.
  def available_pledge
    [remaining_pledge - pending_pledge_amount, 0.to_d].max
  end

  def percent
    return 0 unless investment_goal.to_d.positive?

    (confirmed_pledge_amount / investment_goal * 100).to_i
  end

  private

  def confirmed_pledge_amount
    shareholders.sum(:amount).to_d
  end

  def pending_pledge_amount
    BigDecimal(orders.where(state: 'pending').sum(:amount_cents).to_i) / 100
  end
end
