class CreateJoinTableFromUsersPayments < ActiveRecord::Migration[5.1]
  def change
    create_table :from_users_payments, id: false do |t|
      t.bigint :from_user_id
      t.bigint :payment_id
    end
    add_index :from_users_payments, [:from_user_id, :payment_id]
  end
end
