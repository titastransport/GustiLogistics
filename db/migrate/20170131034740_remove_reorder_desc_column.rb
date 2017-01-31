class RemoveReorderDescColumn < ActiveRecord::Migration[5.0]
  def change
    remove_column :reorders, :description, :string 
  end
end
