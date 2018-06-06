class AddPhoneAltToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :phone_alt, :string
  end
end
