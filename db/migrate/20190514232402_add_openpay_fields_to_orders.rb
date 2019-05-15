class AddOpenpayFieldsToOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :orders, :openpay_id, :string
    add_column :orders, :company, :string
    add_column :orders, :order_status, :string, default: "PROCESSED"
    add_column :orders, :redirect_url, :string
  end
end
