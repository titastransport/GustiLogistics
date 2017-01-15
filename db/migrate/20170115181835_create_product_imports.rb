class CreateProductImports < ActiveRecord::Migration[5.0]
  def change
    create_table :product_imports do |t|

      t.timestamps
    end
  end
end
