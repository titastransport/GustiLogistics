require 'roo'
require 'date'

class UnitActivityReport
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
    file.each_with_index(row_params) do |row, index| 
      if valid_row?(index, row) 
        product_in_row = current_product(row)
        create_activity(product_in_row, row)
        product_in_row.update_current(row[:current])
      end
    end
  end

  def row_params
    { gusti_id: 'Item ID', description: 'Item Description', sold: 'Units Sold', current: 'Qty on Hand'}
  end

  def create_activity(product_in_row, row)
    gusti_id = row[:gusti_id]
    Activity.create!(product_id: product_in_row.id, sold: row[:sold], date: create_datetime) 
  end

  def valid_row?(index, row)
    index != 0 && not_empty_row?(row)
  end

  def not_empty_row?(row)
    row[:gusti_id].to_s != "" && !row[:sold].nil?  
  end

  def current_product(row)
    Product.find_by(gusti_id: row[:gusti_id]) || create_new_product(row) 
  end

  def create_new_product(row)
    Product.create!(gusti_id: row[:gusti_id], description: row[:description], current: row[:current]) 
  end

end
