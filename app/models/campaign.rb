class Campaign < ApplicationRecord
  belongs_to :project
  has_many :shareholders, dependent: :destroy
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
    validates :amount, presence: true
    validates :percentage, presence: true
    validates :photo, presence: { message: "a photo must be uploaded, please" }
  end

  monetize :price_cents

  def active?
    status
  end

  def percent
    pledged_total = 0
    shareholders.each do |sh|
      pledged_total += sh.amount
    end
    ((pledged_total / investment_goal) * 100).to_i
  end
end
