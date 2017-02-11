class RenameProductCantTravelColumn < ActiveRecord::Migration[5.0]
  def change
    rename_column :products, :cant_travel_start, :cant_ship_start
    rename_column :products, :cant_travel_end, :cant_ship_end
  end
end
