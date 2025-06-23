class AddRegisteredInTournament < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :registered_in_tournament, :boolean, default: false
  end
end
