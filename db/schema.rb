# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_06_30_122346) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "campaigns", force: :cascade do |t|
    t.string "name"
    t.datetime "start_date"
    t.datetime "end_date"
    t.text "description"
    t.boolean "status"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "project_id"
    t.index ["project_id"], name: "index_campaigns_on_project_id"
  end

  create_table "messages", force: :cascade do |t|
    t.text "content"
    t.boolean "status"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "user_sender_id"
    t.integer "user_receiver_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "project_name"
    t.string "category"
    t.text "vision"
    t.text "pitch"
    t.string "target"
    t.boolean "status"
    t.string "photo"
    t.bigint "users_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["users_id"], name: "index_projects_on_users_id"
  end

  create_table "shareholders", force: :cascade do |t|
    t.integer "amount"
    t.float "percentage"
    t.boolean "status"
    t.bigint "users_id", null: false
    t.bigint "campaigns_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["campaigns_id"], name: "index_shareholders_on_campaigns_id"
    t.index ["users_id"], name: "index_shareholders_on_users_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.string "category"
    t.integer "amount"
    t.bigint "users_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "status", default: true
    t.index ["users_id"], name: "index_transactions_on_users_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "first_name"
    t.string "last_name"
    t.string "address"
    t.datetime "date_of_birth"
    t.string "gender"
    t.string "phone_number"
    t.boolean "status"
    t.integer "balance"
    t.integer "committed_balance"
    t.boolean "admin"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "campaigns", "projects"
  add_foreign_key "projects", "users", column: "users_id"
  add_foreign_key "shareholders", "campaigns", column: "campaigns_id"
  add_foreign_key "shareholders", "users", column: "users_id"
  add_foreign_key "transactions", "users", column: "users_id"
end
