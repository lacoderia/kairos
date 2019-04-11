class CreateCards < ActiveRecord::Migration[5.1]
  def change
    create_table :cards do |t|
      t.string :openpay_id
      t.string :alias
      t.boolean :active
      t.boolean :is_bank_account, default: false
      t.references :user, foreign_key: true
      t.boolean :primary, default: false
      t.string :holder_name
      t.string :card_number
      t.string :expiration
      t.string :brand
      t.string :company

      t.timestamps
    end
  end
end
