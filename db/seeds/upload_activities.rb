require 'roo'
require 'date'


class UnitActivity
  MATCH_MONTH = /(?<=_)\w+(?=_)/
  MATCH_YEAR = /(?<=_)\d{4}/
  FIRST_OF_MONTH = 1
  attr_reader :file, :file_name

  def initialize(file)
    @file_name = File.basename(file)
    @file = Roo::Spreadsheet.open(file)
  end

  def get_month
    file_name.match(MATCH_MONTH).to_s
  end
  
  def get_year
    file_name.match(MATCH_YEAR).to_s
  end

  def create_datetime
    DateTime.parse("#{FIRST_OF_MONTH}/#{get_month}/#{get_year}")
  end

  def upload_uar
    file.each_with_index(gusti_id: 'Item ID', sold: 'Units Sold') do |row, index| 
      create_activity(row) if valid_row?(index, row) 
    end
  end

  def create_acitivity(row)
    gusti_id = row[:gusti_id]
    Activity.create!(product_id: product_id(row), sold: row[:sold], date: create_datetime) 
  end

  def update_current(row)
    row['Qty on Hand']
  end

  def valid_row?(index, row)
    index != 0 && not_empty_row?(hash[:gusti_id])
  end

  def not_empty_row?(cell)
    cell.to_s != "" 
  end

  def product_id(row)
    Product.find_by(gusti_id: row[:gusti_id]).id || create_new_product(row) 
  end

  def create_new_product(row)
    Product.create!(gusti_id: row['Item ID'], description: row['Item Description'], current: row['Qty on Hand']) 
  end
end
