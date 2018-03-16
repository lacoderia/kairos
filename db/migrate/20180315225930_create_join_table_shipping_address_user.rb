class CreateJoinTableShippingAddressUser < ActiveRecord::Migration[5.1]
  def change
    create_join_table :shipping_addresses, :users do |t|
      t.index [:shipping_address_id, :user_id], name: 'address_id_user_id'
      t.index [:user_id, :shipping_address_id], name: 'user_id_address_id'
    end
  end
end
