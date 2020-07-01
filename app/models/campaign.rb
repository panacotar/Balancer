class Campaign < ApplicationRecord
  belongs_to :user, through: :shareholders
  belongs_to :project
  has_many :shareholders
end
