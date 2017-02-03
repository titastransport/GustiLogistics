class AddActivityTable < ActiveRecord::Migration[5.0]
  def change
    create_table :activities do |t|
      t.integer :sold
      t.date :date
      t.references :product, foreign_key: true

      t.timestamps
    end
    add_index :activities, [:product_id, :date], unique: true
  end
end
