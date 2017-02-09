class RemoveItemIdCpo < ActiveRecord::Migration[5.0]
  def change
    remove_column :customer_purchase_orders, :item_id, :string
  end
end
