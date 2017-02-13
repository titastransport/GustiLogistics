require "dateable"

class PurchaseImport < ApplicationRecord
  include ActiveModel::Model
  include Dateable

  validates :file, presence: true
  attr_accessor :file

  def filename
    File.basename(file.original_filename, File.extname(file.original_filename))
  end

  def save
    purchases = imported_purchases
    if purchases.map(&:valid?).all?
     purchases.each(&:save!)
     true
    else
      purchases.each_with_index do |purchase, index|
        purchase.errors.full_messages.each do |message|
          self.errors.add :base, "Row #{index + 2}: #{message}"
        end
      end
      byebug
      false
    end
  end

  def imported_purchases
    load_imported_purchases
  end

  def wholesale_customer?(row)
    row['Customer ID'].upcase.start_with?('AAA')
  end

  def load_imported_purchases
    spreadsheet = open_spreadsheet
    header = spreadsheet.row(1)
    current_customer = nil
    imported_purchases = (2..spreadsheet.last_row).map do |i|
      row = Hash[[header, spreadsheet.row(i)].transpose]
      current_customer = nil if all_empty_row?(row)
      if not_empty_row?(row)
        break if !wholesale_customer?(row)      
        current_customer = find_or_create_current_customer(row) if current_customer.nil?
        current_customer.customer_purchase_orders.build(purchase_attributes(row))
      end
    end
    byebug
    imported_purchases.compact
  end

  def open_spreadsheet
    Roo::Spreadsheet.open(file.path)
  end

  def create_purchase(product, row)
    customer.customer_purchase_orders.build(sold: row['Units Sold'], date: create_datetime)
  end

  def purchase_attributes(row)
    { quantity: row['Qty'], date: create_datetime, product_id: find_current_product(row).id }
  end

  def all_empty_row?(row)
    row.values.all? { |cell| cell.to_s == "" }
  end

  def not_empty_row?(row)
    row.values.all? { |cell| cell.to_s != "" }
  end

  def find_or_create_current_customer(row)
    Customer.find_or_create_by(name: row['Name'])
  end

  # If not found, gets created and initialized without a current value..
  def find_current_product(row)
    Product.find_or_create_by(gusti_id: row['Item ID']) do |product|
      product.current = 0
    end
  end
end
