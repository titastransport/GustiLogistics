class AddProductDateRanges < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :cant_travel_block, :daterange
  end
end
