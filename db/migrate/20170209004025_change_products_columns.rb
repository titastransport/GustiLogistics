class ChangeProductsColumns < ActiveRecord::Migration[5.0]
  def change
    change_column :products, :growth_factor, :decimal, :precision => 16, :scale => 2

    remove_column :products, :cant_travel
    remove_column :products, :cant_produce

    add_column :products, :cant_travel_start, :date
    add_column :products, :cant_travel_end, :date
    add_column :products, :cant_produce_end, :date

    add_column :products, :cant_produce_start, :date
  end
end
