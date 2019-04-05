class AddBeneficiaryFieldsToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :beneficiary_name, :string
    add_column :users, :beneficiary_dob, :date
    add_column :users, :beneficiary_relationship, :string
    add_column :users, :beneficiary_phone_number, :string
  end
end
