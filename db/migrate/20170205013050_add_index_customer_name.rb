class AddIndexCustomerName < ActiveRecord::Migration[5.0]
  def change
    add_index :customers, :name, unique: true
  end
end
