class AddShippingPriceAndTotalPriceToOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :shipping_price, :float
    add_column :orders, :total_price, :float
    add_reference :orders, :order, foreign_key: true
  end
end
