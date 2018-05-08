class AddQuickStartPaidToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :quick_start_paid, :boolean, default: false 
  end
end
