class ChangeDescriptionColumnName < ActiveRecord::Migration[5.0]
  def change
    rename_column :products, :description, :item_description 
  end
end
