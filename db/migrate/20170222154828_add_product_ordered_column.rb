class AddProductOrderedColumn < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :ordered, :boolean, default: false
  end
end
