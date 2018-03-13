class CreateEmails < ActiveRecord::Migration[5.1]
  def change
    create_table :emails do |t|
      t.references :user, foreign_key: true
      t.string :email_status
      t.string :email_type

      t.timestamps
    end
  end
end
