class Project < ApplicationRecord
  belongs_to :user
  has_many :campaigns, dependent: :destroy
  has_one_attached :photo

  validates :project_name, presence: true

  with_options if: :active? do
    validates :category, presence: true
    validates :vision, presence: true
    validates :pitch, presence: true
    validates :target, presence: true
    validates :photo, presence: { message: "must be given please" }
  end

  def active?
    status
  end
end
