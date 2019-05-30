class AddFieldsToShippingAddresses < ActiveRecord::Migration[5.1]
  def change
    add_column :shipping_addresses, :between_streets, :string
    add_column :shipping_addresses, :reference, :string
    add_column :shipping_addresses, :phone, :string
    add_column :shipping_addresses, :name, :string
  end
end
