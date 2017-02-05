class AddProductIdDateIndexCpo < ActiveRecord::Migration[5.0]
  def change
    add_index :customer_purchase_orders, [:date, :product_id]
  end
end
