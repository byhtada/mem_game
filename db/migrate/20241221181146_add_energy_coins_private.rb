class AddEnergyCoinsPrivate < ActiveRecord::Migration[7.1]
  def change
    remove_column :games, :active
    remove_column :game_users, :active
    remove_column :game_users, :admin
    remove_column :game_users, :ready


    add_column :games, :private, :boolean, default: false

    add_column :users, :energy, :integer, default: 250
    add_column :users, :coins,  :integer, default: 75
  end
end
