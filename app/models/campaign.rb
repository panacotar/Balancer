class Campaign < ApplicationRecord
  belongs_to :project
  has_many :shareholders
  has_one_attached :photo

  validates :name, presence: true, uniqueness: true
  validates :description, length: { maximum: 80 }

  with_options if: :active? do
    validates :start_date, presence: true
    validates :end_date, presence: true
    validates :description, presence: true
    validates :amount, presence: true
    validates :percentage, presence: true
    validates :photo, presence: { message: "must be given please" }
  end

  def active?
    status
  end
end
