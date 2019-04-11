class AddOpenpayIdsToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :prana_openpay_id, :string
    add_column :users, :omein_openpay_id, :string
  end
end
