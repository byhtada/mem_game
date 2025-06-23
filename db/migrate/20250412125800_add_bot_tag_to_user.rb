class AddBotTagToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :bot, :boolean, default: false
  end
end
