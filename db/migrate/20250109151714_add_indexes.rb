class AddIndexes < ActiveRecord::Migration[7.1]
  def change
    add_index :game_users, :game_id, if_not_exists: true
    add_index :rounds, :game_id, if_not_exists: true
    add_index :user_friends, :user_id, if_not_exists: true
  end
end
