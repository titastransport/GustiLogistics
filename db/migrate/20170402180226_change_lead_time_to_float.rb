class ChangeLeadTimeToFloat < ActiveRecord::Migration[5.0]
  def change
    change_column :products, :lead_time, :float
  end
end
