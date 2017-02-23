class RenameProductsOrderedColumnEnroute < ActiveRecord::Migration[5.0]
  def change
    rename_column :products, :ordered, :enroute
  end
end
