class Transaction < ApplicationRecord
  belongs_to :user
  validates :category, inclusion: { in: %w[withdraw top-up investment return] }
  validates :amount, presence: true
end
