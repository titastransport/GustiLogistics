class AddOrderingParametersProduct < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :lead_time, :integer
    add_column :products, :travel_time, :integer
    add_column :products, :cover_time, :integer
    add_column :products, :cant_ship, :daterange
    add_column :products, :cant_produce, :daterange
    add_column :products, :growth_factor, :decimal
    add_column :products, :producer, :string
  end
end
