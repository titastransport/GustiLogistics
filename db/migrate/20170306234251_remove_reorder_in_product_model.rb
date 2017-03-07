class RemoveReorderInProductModel < ActiveRecord::Migration[5.0]
  def change
    remove_column :products, :reorder_in
  end
end
