class AddSouce < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :source_channel, :string
    add_column :users, :source_id, :string

    add_index :users, :source_channel
  end
end
