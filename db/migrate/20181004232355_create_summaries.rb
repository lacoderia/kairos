class CreateSummaries < ActiveRecord::Migration[5.1]
  def change
    create_table :summaries do |t|
      t.references :user, foreign_key: true
      t.datetime :period_start
      t.datetime :period_end
      t.integer :current_omein_vg
      t.integer :current_omein_vp
      t.integer :current_prana_vg
      t.integer :current_prana_vp
      t.integer :previous_omein_vg
      t.integer :previous_omein_vp
      t.integer :previous_prana_vg
      t.integer :previous_prana_vp
      t.string :previous_rank
    end
  end
end
