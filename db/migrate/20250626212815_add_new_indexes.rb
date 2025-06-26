class AddNewIndexes < ActiveRecord::Migration[7.1]
  def change
    # Индексы для таблицы games
    add_index :games, :state, if_not_exists: true
    add_index :games, [:state, :private], if_not_exists: true
    add_index :games, [:uniq_id, :state, :private], if_not_exists: true
    
    # Индексы для таблицы game_users
    add_index :game_users, [:user_id, :game_id], if_not_exists: true
    add_index :game_users, :user_id, if_not_exists: true
    add_index :game_users, :bot, if_not_exists: true
    
    # Индексы для таблицы users
    add_index :users, :tg_id, if_not_exists: true
    add_index :users, :auth_token, if_not_exists: true
    add_index :users, :bot, if_not_exists: true
    
    # Индексы для таблицы tournament_users
    add_index :tournament_users, :user_id, if_not_exists: true
    add_index :tournament_users, :tournament_id, if_not_exists: true
    add_index :tournament_users, [:user_id, :tournament_id], if_not_exists: true
    
    # Индексы для таблицы rounds (дополнительные)
    add_index :rounds, :state, if_not_exists: true
    add_index :rounds, [:game_id, :state], if_not_exists: true
    
    # Индексы для таблицы user_friends (дополнительные)
    add_index :user_friends, :friend_id, if_not_exists: true
    add_index :user_friends, [:user_id, :friend_id], if_not_exists: true
    
    # Индексы для таблицы tournaments
    add_index :tournaments, :active, if_not_exists: true
    add_index :tournaments, :start, if_not_exists: true
  end
end 