class AddEnergyMax < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :energy_max, :float, default: 250
  end
end
