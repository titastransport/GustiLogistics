class RenameProductImportToAcitivityImport < ActiveRecord::Migration[5.0]
  def change
    def change
      rename_table :product_imports, :activity_imports
    end
  end
end
