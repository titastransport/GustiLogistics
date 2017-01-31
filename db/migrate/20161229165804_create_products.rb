class CreateProducts < ActiveRecord::Migration[5.0]
  def change
    create_table :products do |t|
      t.string  :gusti_id
      t.string  :description
      t.integer :current
      t.integer :reorder_in

      t.timestamps
    end
  end
end
