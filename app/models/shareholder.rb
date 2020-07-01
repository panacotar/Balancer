class Shareholder < ApplicationRecord
  belongs_to :user
  belongs_to :campaign
  validates :status, inclusion: { in: %w[Active Inactive Committed] }
end
