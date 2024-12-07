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

ActiveRecord::Schema[7.1].define(version: 2024_10_20_135004) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "game_users", force: :cascade do |t|
    t.integer "game_id"
    t.integer "game_points", default: 0
    t.integer "game_user_number"
    t.integer "user_id"
    t.string "user_name"
    t.string "user_ava"
    t.boolean "ready", default: false
    t.boolean "admin", default: false
    t.string "mem_names", default: ""
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_game_users_on_game_id"
  end

  create_table "games", force: :cascade do |t|
    t.integer "uniq_id"
    t.integer "participants", default: 4
    t.integer "current_round", default: 0
    t.boolean "active", default: true
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "mems", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "questions", force: :cascade do |t|
    t.string "style"
    t.boolean "adult", default: false
    t.string "text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "rounds", force: :cascade do |t|
    t.integer "game_id"
    t.integer "round_num"
    t.integer "question_id"
    t.string "question_text"
    t.boolean "active", default: true
    t.integer "start_voting", default: 0
    t.string "mem_0_name", default: ""
    t.string "mem_1_name", default: ""
    t.string "mem_2_name", default: ""
    t.string "mem_3_name", default: ""
    t.string "mem_4_name", default: ""
    t.integer "mem_0_votes", default: 0
    t.integer "mem_1_votes", default: 0
    t.integer "mem_2_votes", default: 0
    t.integer "mem_3_votes", default: 0
    t.integer "mem_4_votes", default: 0
    t.decimal "mem_0_time", default: "0.0"
    t.decimal "mem_1_time", default: "0.0"
    t.decimal "mem_2_time", default: "0.0"
    t.decimal "mem_3_time", default: "0.0"
    t.decimal "mem_4_time", default: "0.0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id", "round_num"], name: "index_rounds_on_game_id_and_round_num", unique: true
    t.index ["game_id"], name: "index_rounds_on_game_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", default: ""
    t.string "ava", default: ""
    t.integer "tg_id"
    t.string "auth_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
