class AddMemNameRu < ActiveRecord::Migration[7.1]
  def change
    add_column :mems, :name_ru, :string
    add_column :mems, :link_video, :string
    add_column :mems, :link_image, :string
  end
end
