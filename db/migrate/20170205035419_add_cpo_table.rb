class AddCpoTable < ActiveRecord::Migration[5.0]
  def change
    create_table :customer_purchase_orders do |t|
      t.date :date
      t.integer :quantity
      t.references :product, foreign_key: true, index: true
      t.references :customer, foreign_key: true, index: true
    end
    add_index :customer_purchase_orders, [:customer_id, :date, \
              :product_id], unique: true, name: :my_index
  end
end
