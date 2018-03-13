class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.string :first_name
      t.string :last_name
      t.integer :external_id
      t.integer :sponsor_external_id
      t.integer :placement_external_id
      t.string :phone
      t.boolean :active

      t.timestamps
    end
  end
end
