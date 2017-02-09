class ChangeCantShipColumn < ActiveRecord::Migration[5.0]
  def change
    rename_column :products, :cant_ship, :cant_travel
  end
end
