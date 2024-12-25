class AddActiveToGameUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :game_users, :active, :boolean, default: true
  end
end
