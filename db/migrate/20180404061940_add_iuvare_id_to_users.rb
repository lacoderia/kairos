class AddIuvareIdToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :iuvare_id, :string
  end
end
