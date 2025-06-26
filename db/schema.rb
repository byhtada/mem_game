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

ActiveRecord::Schema[7.1].define(version: 2025_06_26_212815) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "game_users", force: :cascade do |t|
    t.integer "game_id"
    t.integer "game_points", default: 0
    t.integer "game_user_number"
    t.integer "user_id"
    t.string "user_name"
    t.string "user_ava"
    t.string "mem_names", default: ""
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "ready_to_restart", default: false
    t.boolean "bot", default: false
    t.index ["bot"], name: "index_game_users_on_bot"
    t.index ["game_id"], name: "index_game_users_on_game_id"
    t.index ["user_id", "game_id"], name: "index_game_users_on_user_id_and_game_id"
    t.index ["user_id"], name: "index_game_users_on_user_id"
  end

  create_table "games", force: :cascade do |t|
    t.integer "uniq_id"
    t.integer "participants", default: 4
    t.integer "current_round", default: 0
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "state", default: "registration"
    t.boolean "private", default: false
    t.index ["state", "private"], name: "index_games_on_state_and_private"
    t.index ["state"], name: "index_games_on_state"
    t.index ["uniq_id", "state", "private"], name: "index_games_on_uniq_id_and_state_and_private"
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
    t.string "state", default: "play"
    t.index ["game_id", "round_num"], name: "index_rounds_on_game_id_and_round_num", unique: true
    t.index ["game_id", "state"], name: "index_rounds_on_game_id_and_state"
    t.index ["game_id"], name: "index_rounds_on_game_id"
    t.index ["state"], name: "index_rounds_on_state"
  end

  create_table "tournament_users", force: :cascade do |t|
    t.integer "user_id"
    t.integer "tournament_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tournament_id"], name: "index_tournament_users_on_tournament_id"
    t.index ["user_id", "tournament_id"], name: "index_tournament_users_on_user_id_and_tournament_id"
    t.index ["user_id"], name: "index_tournament_users_on_user_id"
  end

  create_table "tournaments", force: :cascade do |t|
    t.datetime "start"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_tournaments_on_active"
    t.index ["start"], name: "index_tournaments_on_start"
  end

  create_table "user_friends", force: :cascade do |t|
    t.integer "user_id"
    t.integer "friend_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["friend_id"], name: "index_user_friends_on_friend_id"
    t.index ["user_id", "friend_id"], name: "index_user_friends_on_user_id_and_friend_id"
    t.index ["user_id"], name: "index_user_friends_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", default: ""
    t.string "ava", default: ""
    t.bigint "tg_id"
    t.string "auth_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "energy", default: 250.0
    t.integer "coins", default: 75
    t.boolean "premium", default: false
    t.float "energy_max", default: 250.0
    t.boolean "registered_in_tournament", default: false
    t.string "source_channel"
    t.string "source_id"
    t.boolean "bot", default: false
    t.index ["auth_token"], name: "index_users_on_auth_token"
    t.index ["bot"], name: "index_users_on_bot"
    t.index ["source_channel"], name: "index_users_on_source_channel"
    t.index ["tg_id"], name: "index_users_on_tg_id"
  end

end
