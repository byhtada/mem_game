# frozen_string_literal: true

class Initial < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :name, default: ''
      t.string :ava,  default: ''

      t.bigint :tg_id

      t.string :auth_token
      t.timestamps
    end

    create_table :games do |t|
      t.integer :uniq_id
      t.integer :participants, default: 4
      t.integer :current_round, default: 0
      t.boolean :active, default: true
      t.string :type
      t.timestamps
    end

    create_table :rounds do |t|
      t.integer :game_id
      t.integer :round_num

      t.integer :question_id
      t.string  :question_text

      t.boolean :active, default: true
      t.integer :start_voting, default: 0

      t.string :mem_0_name, default: ''
      t.string :mem_1_name, default: ''
      t.string :mem_2_name, default: ''
      t.string :mem_3_name, default: ''
      t.string :mem_4_name, default: ''

      t.integer :mem_0_votes, default: 0
      t.integer :mem_1_votes, default: 0
      t.integer :mem_2_votes, default: 0
      t.integer :mem_3_votes, default: 0
      t.integer :mem_4_votes, default: 0

      t.decimal :mem_0_time, default: 0
      t.decimal :mem_1_time, default: 0
      t.decimal :mem_2_time, default: 0
      t.decimal :mem_3_time, default: 0
      t.decimal :mem_4_time, default: 0

      t.timestamps
    end

    add_index :rounds, :game_id
    add_index :rounds, %i[game_id round_num], unique: true

    create_table :game_users do |t|
      t.integer :game_id
      t.integer :game_points, default: 0
      t.integer :game_user_number

      t.integer :user_id
      t.string :user_name
      t.string :user_ava

      t.boolean :ready, default: false
      t.boolean :admin, default: false
      t.string :mem_names, default: ''

      t.timestamps
    end
    add_index :game_users, :game_id

    create_table :questions do |t|
      t.string  :style
      t.boolean :adult, default: false
      t.string  :text
      t.timestamps
    end

    create_table :mems do |t|
      t.string :name
      t.timestamps
    end
  end
end
