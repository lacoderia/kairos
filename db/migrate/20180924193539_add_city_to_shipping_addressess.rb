class AddCityToShippingAddressess < ActiveRecord::Migration[5.1]
  def change
    add_column :shipping_addresses, :city, :string
  end
end
