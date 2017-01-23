class CreateReorders < ActiveRecord::Migration[5.0]
  def change
    create_table :reorders do |t|
      t.date :date
      t.integer :quantity
      t.string :description
      t.references :product, foreign_key: true

      t.timestamps
    end
    add_index :reorders, :description
  end
end
