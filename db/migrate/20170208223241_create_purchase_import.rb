class CreatePurchaseImport < ActiveRecord::Migration[5.0]
  def change
    create_table :purchase_imports do |t|

      t.timestamps
    end
  end
end
