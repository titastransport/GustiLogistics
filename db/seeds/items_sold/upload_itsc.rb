require 'roo'
require_relative '../seed_helper'

class ItemsSoldToCustomers
  include Dateable
  attr_reader :file, :file_name

  def initialize(file)
    @file_name = File.basename(file, File.extname(file))
    @file = Roo::Spreadsheet.open(file)
  end

  def upload_itsc
    current_customer = nil
    file.each_with_index(row_params) do |row, index|
      current_customer = nil if all_empty_row?(row)
      if valid_row?(index, row) && faella_product?(row[:gusti_id])
        current_customer = find_current_customer(row) if current_customer.nil? 
        create_purchase(current_customer, row)
      end
    end
  end

  # Starting with only Faella product so must exclude others despite 2015 upload
  # of all..
  def faella_product?(gusti_id)
    Product.find_by(gusti_id: gusti_id).producer == "Faella"
  end

  def create_purchase(current_customer, row)
    quantity, date, product_id = row[:purchase_quantity], create_datetime, find_current_product(row).id 
    current_customer.customer_purchase_orders.create!(quantity: quantity, date: date, \
                                                     product_id: product_id) 
  end

  def find_current_product(row)
    Product.find_by(gusti_id: row[:gusti_id]) || (Product.create!(gusti_id: row[:gusti_id], current: 0))
  end

  def find_current_customer(row)
    Customer.find_by(name: row[:customer_name]) || Customer.create!(name: row[:customer_name])
  end

  def all_empty_row?(row)
    row.values.all? { |v| v.to_s == "" }
  end

  def valid_row?(index, row)
    not_header_row?(index) && not_empty_row?(row)
  end

  def not_header_row?(index)
    !index.zero?
  end

  def not_empty_row?(row)
    # all row params must not be nil
    row.values.all? { |v| v.to_s != "" }
  end

  def row_params
    { gusti_id: 'Item ID', customer_name: 'Name', purchase_quantity: 'Qty' }
  end
end
