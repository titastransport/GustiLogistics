class FixColumnNames < ActiveRecord::Migration[5.0]
  def change
    rename_column :products, :item_id, :gusti_id
    rename_column :products, :item_description, :description
  end
end
