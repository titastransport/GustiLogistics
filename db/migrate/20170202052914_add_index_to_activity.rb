class AddIndexToActivity < ActiveRecord::Migration[5.0]
  def change
    add_index :activities, [:product_id, :date], unique: true
  end
end
