class Project < ApplicationRecord
  belongs_to :user
  has_many :campaigns

  validates :project_name, presence: true
  validates :category, presence: true
  validates :vision, presence: true
  validates :pitch, presence: true
  validates :target, presence: true

end


# t.string "project_name"
#     t.string "category"
#     t.text "vision"
#     t.text "pitch"
#     t.string "target"
#     t.boolean "status"