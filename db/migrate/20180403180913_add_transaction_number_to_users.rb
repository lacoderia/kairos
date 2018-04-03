class AddTransactionNumberToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :transaction_number, :string
  end
end
