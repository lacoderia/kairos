class ChangeDescriptionTypeToItems < ActiveRecord::Migration[5.1]
  def change
    change_column :items, :description, :text    
  end
end
