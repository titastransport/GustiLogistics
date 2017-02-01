class ChangeProductImportsName < ActiveRecord::Migration[5.0]
  def change
    rename_table :product_imports, :activity_imports
  end
end
