class UpdatePurchases < ActiveRecord::Migration[5.0]
  def change
    remove_column :purchases, :customer, :string
    add_foreign_key :products, :purchases
    add_foreign_key :customers, :purchases
    add_column :purchases, :date, :daterange
    rename_table :purchases, :customerpurchaseorders
  end
end
