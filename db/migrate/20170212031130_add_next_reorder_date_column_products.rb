class AddNextReorderDateColumnProducts < ActiveRecord::Migration[5.0]
  def change
    add_column :products, :next_reorder_date, :date
  end
end
