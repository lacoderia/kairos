class CreateOrders < ActiveRecord::Migration[5.1]
  def change
    create_table :orders do |t|
      t.string :description
      t.integer :item_id

      t.timestamps
    end
  end
end
