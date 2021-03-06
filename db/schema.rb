# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20160924044720) do

  create_table "museums", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.integer  "type",       limit: 4
    t.string   "url",        limit: 255
    t.time     "open_time"
    t.time     "close_time"
    t.string   "sleep",      limit: 255
    t.string   "address",    limit: 255
    t.boolean  "del_flg"
    t.integer  "pref_id",    limit: 4
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "museums", ["pref_id"], name: "index_museums_on_pref_id", using: :btree

  create_table "prefs", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "spexhabits", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "url",        limit: 255
    t.datetime "start_date"
    t.datetime "end_date"
    t.boolean  "del_flg"
    t.integer  "status",     limit: 4
    t.integer  "museum_id",  limit: 4
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "spexhabits", ["museum_id"], name: "index_spexhabits_on_museum_id", using: :btree

  add_foreign_key "museums", "prefs"
  add_foreign_key "spexhabits", "museums"
end
