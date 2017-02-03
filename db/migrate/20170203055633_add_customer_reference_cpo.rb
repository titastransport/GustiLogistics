class AddCustomerReferenceCpo < ActiveRecord::Migration[5.0]
  def change
    add_reference :customer_purchase_orders, :customer, index: true
    add_foreign_key :customer_purchase_orders, :customers
  end
end
