class AddCustomerPurchaseReferences < ActiveRecord::Migration[5.0]
  def change
    add_reference :customer_purchase_orders, :product, index: true
  end
end
