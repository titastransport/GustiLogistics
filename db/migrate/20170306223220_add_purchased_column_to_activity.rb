class AddPurchasedColumnToActivity < ActiveRecord::Migration[5.0]
  def change
    add_column :activities, :purchased, :integer, default: 0 
  end
end
