class StoreDecimalAsString < ActiveRecord::Migration[5.0]
  def change
    change_column :products, :growth_factor, :string
  end
end
