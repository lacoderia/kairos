class AddActiveToShippingAddresses < ActiveRecord::Migration[5.1]
  def change
    add_column :shipping_addresses, :active, :boolean, default: true
  end
end
