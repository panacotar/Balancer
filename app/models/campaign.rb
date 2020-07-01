class Campaign < ApplicationRecord
  belongs_to :project
  has_many :shareholders
end
