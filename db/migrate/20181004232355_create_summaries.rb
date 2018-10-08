class CreateSummaries < ActiveRecord::Migration[5.1]
  def change
    create_table :summaries do |t|
      t.references :user, foreign_key: true
      t.datetime :period_start
      t.datetime :period_end
      t.integer :omein_vg, default: 0
      t.integer :omein_vp, default: 0
      t.integer :prana_vg, default: 0
      t.integer :prana_vp, default: 0
      t.string :rank, default: "N/A"
    end

    add_index :summaries, [:user_id, :period_start, :period_end], unique: true
  end
end
