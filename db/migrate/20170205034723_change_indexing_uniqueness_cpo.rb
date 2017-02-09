class ChangeIndexingUniquenessCpo < ActiveRecord::Migration[5.0]
  def change
    remove_index :customer_purchase_orders, :customer_id
  end
end
