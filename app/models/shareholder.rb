class Shareholder < ApplicationRecord
  belongs_to :users
  belongs_to :campaigns
end
