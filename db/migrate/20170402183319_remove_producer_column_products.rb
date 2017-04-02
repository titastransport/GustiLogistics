class RemoveProducerColumnProducts < ActiveRecord::Migration[5.0]
  def change
    remove_column :products, :producer
  end
end
