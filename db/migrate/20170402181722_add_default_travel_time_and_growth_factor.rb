class AddDefaultTravelTimeAndGrowthFactor < ActiveRecord::Migration[5.0]
  def change
    change_column_default :products, :travel_time, 1
    change_column_default :products, :growth_factor, "1.2"
  end
end
