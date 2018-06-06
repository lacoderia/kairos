class RemoveItemIdFromOrders < ActiveRecord::Migration[5.1]
  def change
    remove_column :orders, :item_id
  end
end
