class AddOrderNumberToOrder < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :order_number, :string
  end
end
