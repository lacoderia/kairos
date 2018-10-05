class AddMaxRankToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :max_rank, :string, default: "Empresario"
  end
end
