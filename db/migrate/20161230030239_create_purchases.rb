class CreatePurchases < ActiveRecord::Migration[5.0]
  def change
    create_table :purchases do |t|
      t.string :customer
      t.string :product
      t.integer :quantity

      t.timestamps
    end
  end
end
