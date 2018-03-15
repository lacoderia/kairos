class CreateInvitations < ActiveRecord::Migration[5.0]
  def change
    create_table :invitations do |t|
      t.references :user, foreign_key: true
      t.string :recipient_name
      t.string :recipient_email
      t.string :token
      t.boolean :used, default: false

      t.timestamps
    end
  end
end
