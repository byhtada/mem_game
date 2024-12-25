class AddReadyToRestart < ActiveRecord::Migration[7.1]
  def change
    add_column :game_users, :ready_to_restart, :boolean, default: false
  end
end
