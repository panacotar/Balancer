class Campaign < ApplicationRecord
  belongs_to :project
  has_many :shareholders

  validates :name, presence: true, uniqueness: true

  with_options if: :active? do
    validates :start_date, presence: true
    validates :end_date, presence: true
    validates :description, presence: true
    validates :amount, presence: true
    validates :percentage, presence: true
  end

  def active?
    status
  end
end
