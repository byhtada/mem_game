class AddContext < ActiveRecord::Migration[7.1]
  def change
    add_column :questions, :context, :string
    add_column :mems, :context, :jsonb, default: []
  end
end
