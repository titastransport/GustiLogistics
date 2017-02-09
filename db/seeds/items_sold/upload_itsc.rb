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
      if valid_row?(index, row)
        current_customer = find_current_customer(row) if current_customer.nil?
        potential_purchase = \
          current_customer.customer_purchase_orders.new(purchase_attributes(row))
        potential_purchase.save if potential_purchase.valid?
      end
    end
  end

  def purchase_attributes(row)
    { quantity: row[:purchase_quantity], date: create_datetime,\
      product_id: find_current_product(row).id }
  end

  def find_current_product(row)
    Product.find_or_create_by(gusti_id: row[:gusti_id]) do |product|
      product.current = 0
    end
  end

  def find_current_customer(row)
    Customer.find_or_create_by(name: row[:customer_name])
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
