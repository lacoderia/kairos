class AddNewRankToSummaries < ActiveRecord::Migration[5.1]
  def change
    add_column :summaries, :new_rank, :boolean, default: false
  end
end
