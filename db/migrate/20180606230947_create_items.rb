class CreateItems < ActiveRecord::Migration[5.1]
  def change
    create_table :items do |t|
      t.string :company
      t.string :name
      t.string :description
      t.float :price
      t.float :commissionable_value
      t.integer :volume

      t.timestamps
    end
  end
end
