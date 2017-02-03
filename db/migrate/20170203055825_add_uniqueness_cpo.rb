class AddUniquenessCpo < ActiveRecord::Migration[5.0]
  def change
    add_index :customer_purchase_orders, [:customer_id, :date], unique: true
  end
end
