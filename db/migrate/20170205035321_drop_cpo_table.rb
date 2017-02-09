class DropCpoTable < ActiveRecord::Migration[5.0]
  def change
    drop_table :customer_purchase_orders
  end
end
