class AddBotTagToGameUser < ActiveRecord::Migration[7.1]
  def change
    add_column :game_users, :bot, :boolean, default: false
  end
end
