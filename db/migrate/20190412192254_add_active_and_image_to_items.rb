class AddActiveAndImageToItems < ActiveRecord::Migration[5.1]
  def change
    add_column :items, :active, :boolean, default: :true
    add_column :items, :image, :string
  end
end
