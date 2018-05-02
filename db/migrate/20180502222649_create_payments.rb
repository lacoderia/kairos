class CreatePayments < ActiveRecord::Migration[5.1]
  def change
    create_table :payments do |t|
      t.float :amount
      t.string :payment_type
      t.string :term_paid

      t.timestamps
    end
  end
end
