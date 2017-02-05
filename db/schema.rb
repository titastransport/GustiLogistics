# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170205035419) do

  create_table "activities", force: :cascade do |t|
    t.integer  "sold"
    t.date     "date"
    t.integer  "product_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id", "date"], name: "index_activities_on_product_id_and_date", unique: true
    t.index ["product_id"], name: "index_activities_on_product_id"
  end

  create_table "activity_imports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "customer_purchase_orders", force: :cascade do |t|
    t.date    "date"
    t.integer "quantity"
    t.integer "product_id"
    t.integer "customer_id"
    t.index ["customer_id", "date", "product_id"], name: "my_index", unique: true
    t.index ["customer_id"], name: "index_customer_purchase_orders_on_customer_id"
    t.index ["product_id"], name: "index_customer_purchase_orders_on_product_id"
  end

  create_table "customers", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_customers_on_name", unique: true
  end

  create_table "products", force: :cascade do |t|
    t.string   "gusti_id"
    t.string   "description"
    t.integer  "current"
    t.integer  "reorder_in"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.integer  "lead_time"
    t.integer  "travel_time"
    t.integer  "cover_time"
    t.date     "cant_ship"
    t.date     "cant_produce"
    t.decimal  "growth_factor"
    t.string   "producer"
    t.index ["gusti_id"], name: "index_products_on_gusti_id", unique: true
  end

  create_table "reorders", force: :cascade do |t|
    t.date     "date"
    t.integer  "quantity"
    t.integer  "product_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_reorders_on_product_id"
  end

  create_table "users", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "email"
    t.string   "password_digest"
    t.string   "remember_digest"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

end
