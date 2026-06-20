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

ActiveRecord::Schema[7.2].define(version: 2026_06_17_144558) do
  create_table "hobby_items", force: :cascade do |t|
    t.string "title", null: false
    t.string "category"
    t.string "item_type", default: "memo", null: false
    t.date "scheduled_on"
    t.string "location"
    t.integer "cost", default: 0, null: false
    t.string "url"
    t.text "body"
    t.integer "rating"
    t.string "status", default: "planned", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_type"], name: "index_hobby_items_on_item_type"
    t.index ["scheduled_on"], name: "index_hobby_items_on_scheduled_on"
    t.index ["status"], name: "index_hobby_items_on_status"
  end

  create_table "lunch_logs", force: :cascade do |t|
    t.date "visited_on", null: false
    t.string "shop_name", null: false
    t.string "area"
    t.integer "price", default: 0, null: false
    t.integer "rating", default: 3, null: false
    t.string "crowdedness", default: "普通", null: false
    t.boolean "solo_friendly", default: false, null: false
    t.boolean "repeat", default: false, null: false
    t.text "memo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["rating"], name: "index_lunch_logs_on_rating"
    t.index ["visited_on"], name: "index_lunch_logs_on_visited_on"
  end

  create_table "paid_rides", force: :cascade do |t|
    t.date "used_on", null: false
    t.string "line_name", default: "京王ライナー", null: false
    t.string "direction"
    t.integer "fare", default: 410, null: false
    t.string "reason"
    t.integer "fatigue_level", default: 3, null: false
    t.text "memo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["used_on"], name: "index_paid_rides_on_used_on"
  end

  create_table "work_days", force: :cascade do |t|
    t.date "date", null: false
    t.boolean "check_in_confirmed", default: false, null: false
    t.boolean "check_out_confirmed", default: false, null: false
    t.datetime "check_in_confirmed_at"
    t.datetime "check_out_confirmed_at"
    t.text "memo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_work_days_on_date", unique: true
  end
end
