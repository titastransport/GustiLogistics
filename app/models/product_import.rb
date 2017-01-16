class ProductImport < ApplicationRecord
  attr_accessor :file

  def save
    if imported_products.map(&:valid?).all?
     imported_products.each(&:save!)
     true
    else
      imported_prodcuts.each_with_index do |product, index|
        product.errors.full_messages.each do |message|
          errors.add :base, "Row #{index + 2}: #{message}"
        end
      end
      false
    end
  end

  def imported_products
    load_imported_products
  end

  def load_imported_products
    spreadsheet = open_spreadsheet
    header = spreadsheet.row(1)
    imported_products = (2..spreadsheet.last_row).map do |i|
      row = Hash[[header, spreadsheet.row(i)].transpose]
      if row['Item ID'].to_s != ''
        product = Product.find_by(item_id: row["Item ID"]) || create_new_product(row)
        product.current = row['Qty on Hand']
        product
      end
    end
    imported_products.compact
  end 

  def open_spreadsheet
    Roo::Spreadsheet.open(file.path) 
  end

  def create_new_product(row)
    Product.create(item_id: row['Item ID'], description: row['Item Description'], current: row['Beg Qty'], reorder_in: 999) 
  end

end
