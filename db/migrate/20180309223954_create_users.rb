class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.string :first_name
      t.string :last_name
      t.integer :external_id, null: false
      t.integer :sponsor_external_id, null: false
      t.integer :placement_external_id, null: false
      t.string :phone
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
