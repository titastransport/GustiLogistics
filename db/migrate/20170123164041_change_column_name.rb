class ChangeColumnName < ActiveRecord::Migration[5.0]
  def change
    rename_column :purchases, :product, :item_id
  end
end
