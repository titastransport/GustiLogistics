class AddIndexToProductsGustiId < ActiveRecord::Migration[5.0]
  def change
    add_index :products, :gusti_id, unique: true
  end
end
