# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_31_012918) do
  create_table "categories", force: :cascade do |t|
    t.string "category_type", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
  end

  create_table "monthly_periods", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "month", null: false
    t.decimal "starting_balance", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.integer "year", null: false
    t.index ["year", "month"], name: "index_monthly_periods_on_year_and_month", unique: true
  end

  create_table "transactions", force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.integer "category_id", null: false
    t.datetime "created_at", null: false
    t.integer "created_by_id", null: false
    t.date "date", null: false
    t.string "description"
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_transactions_on_category_id"
    t.index ["created_by_id"], name: "index_transactions_on_created_by_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.boolean "approved", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "transactions", "categories"
  add_foreign_key "transactions", "users", column: "created_by_id"
end
