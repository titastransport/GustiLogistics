class AddIndexes < ActiveRecord::Migration[5.0]
  def change
    add_index :products, :producer

    add_index :activities, :date
    add_index :customer_purchase_orders, :date
  end
end
