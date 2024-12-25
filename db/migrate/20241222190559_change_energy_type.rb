class ChangeEnergyType < ActiveRecord::Migration[7.1]
  def change
    change_column :users, :energy, :float
  end
end
