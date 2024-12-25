class CreateTournaments < ActiveRecord::Migration[7.1]
  def change
    create_table :tournaments do |t|
      t.datetime :start
      t.boolean :active
      t.timestamps
    end
  end
end
