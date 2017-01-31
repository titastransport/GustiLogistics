class CreateActivities < ActiveRecord::Migration[5.0]
  def change
    create_table :activities do |t|
      t.date :date
      t.integer :sold
      t.references :product, foreign_key: true

      t.timestamps
    end
  end
end
