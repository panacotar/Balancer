class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :projects
  has_many :shareholders
  has_many :transactions
  has_many :campaigns, through: :projects
  has_many :user_senders, class_name: 'User', foreign_key: :user_sender_id
  has_many :user_receivers, class_name: 'User', foreign_key: :user_receiver_id

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :date_of_birth, presence: true
  validates :address, presence: true
  validates :gender, presence: true
  validates :phone_number, presence: true

  validates :first_name, length: { minimum: 2 }
  validates :phone_number, uniqueness: true
  validates :gender, inclusion: { in: %w[male female transgender gender-neutral agender pangender genderqueer two-spirit third-gender others] }
end

# t.string "email", default: "", null: false
#     t.string "encrypted_password", default: "", null: false
#     t.string "reset_password_token"
#     t.datetime "reset_password_sent_at"
#     t.datetime "remember_created_at"
#     t.datetime "created_at", precision: 6, null: false
#     t.datetime "updated_at", precision: 6, null: false
#     t.string "first_name"
#     t.string "last_name"
#     t.string "address"
#     t.datetime "date_of_birth"
#     t.string "gender"
#     t.string "phone_number"
#     t.boolean "status"
#     t.integer "balance"
#     t.integer "committed_balance"
#     t.boolean "admin"
#     t.index ["email"], name: "index_users_on_email", unique: true
#     t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
