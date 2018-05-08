class AddUniqueIndexesOnUsers < ActiveRecord::Migration[5.1]
  def change
    add_index :users, :external_id, unique: true
#    add_index :users, :iuvare_id, unique: true
  end
end
