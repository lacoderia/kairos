class CreateShippingAddresses < ActiveRecord::Migration[5.1]
  def change
    create_table :shipping_addresses do |t|
      t.string :address
      t.string :state
      t.string :location
      t.string :zip
      t.string :country

      t.timestamps
    end
  end
end
