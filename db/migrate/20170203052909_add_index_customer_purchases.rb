class AddIndexCustomerPurchases < ActiveRecord::Migration[5.0]
  def change
    rename_table :customerpurchaseorders, :customer_purchase_orders
  end
end
