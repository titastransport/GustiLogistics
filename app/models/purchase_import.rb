class PurchaseImport < ApplicationRecord
  attr_accessor :file

  def save
    if imported_purchases.map(&:valid?).all?
     imported_purchases.each(&:save!)
     true
    else
      imported_purchases.each_with_index do |purchase, index|
        purchase.errors.full_messages.each do |message|
          errors.add :base, "Row #{index + 2}: #{message}"
        end
      end
      false
    end
  end

  def imported_purchases
    load_imported_purchases
  end

  def load_imported_purchases
    spreadsheet = open_spreadsheet
    header = spreadsheet.row(1)
    imported_purchases = (2..spreadsheet.last_row).map do |i|
      row = Hash[[header, spreadsheet.row(i)].transpose]
    end
    imported_purchases.compact
  end 

  def customer
    Customer.find_by()
  end

  def create_new_purchase(row)
    Customer.purchases.create(gusti_id: row['Item ID'], current: row['Qty on Hand'], reorder_in: 999) 
  end

  def open_spreadsheet
    Roo::Spreadsheet.open(file.path) 
  end

end
