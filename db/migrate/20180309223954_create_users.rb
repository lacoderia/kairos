class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.string :first_name
      t.string :last_name
      t.bigint :external_id, null: false
      t.bigint :sponsor_external_id, null: false
      t.bigint :placement_external_id, null: false
      t.string :phone
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
