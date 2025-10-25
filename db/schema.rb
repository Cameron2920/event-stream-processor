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

ActiveRecord::Schema[7.2].define(version: 2025_10_23_160446) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "event_metrics", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "events", force: :cascade do |t|
    t.string "event_id", null: false
    t.string "event_type", null: false
    t.jsonb "payload", default: {}
    t.string "source"
    t.datetime "occurred_at", null: false
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_events_on_event_id", unique: true
    t.index ["event_type"], name: "index_events_on_event_type"
    t.index ["occurred_at"], name: "index_events_on_occurred_at"
    t.index ["processed_at"], name: "index_events_on_processed_at"
  end
end
