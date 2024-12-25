class AddStateToGame < ActiveRecord::Migration[7.1]
  def change
    add_column :games, :state, :string, default: 'registration'
    add_column :rounds, :state, :string, default: 'play'
  end
end
