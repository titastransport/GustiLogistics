require 'roo'
require 'date'

class UnitActivityReport
  MATCH_MONTH = /[a-zA-Z]{3,10}/
  MATCH_YEAR = /\d{4}/
  NOT_ALL_CAPS = /[^A-Z]/
  FIRST_OF_MONTH = 1
  attr_reader :file, :file_name, :month, :year

  def initialize(file)
    @file_name = File.basename(file, File.extname(file))
    @file = Roo::Spreadsheet.open(file)
    @month, @year = parse_file_name
  end

  def parse_file_name
    # File must be seperate by _ and contain maximum UAR, month, and year..
    parts = file_name.split(/_/).select { |el| el =~ NOT_ALL_CAPS }
    [get_month(parts), get_year(parts)]
  end

  def get_month(arr)
    arr.select { |el| el =~ MATCH_MONTH }.first
  end
  
  def get_year(arr)
    arr.select { |el| el =~ MATCH_YEAR }.first
  end

  def create_datetime
    DateTime.parse("#{FIRST_OF_MONTH}/#{month}/#{year}")
  end

  def upload_uar
    file.each_with_index(row_params) do |row, index| 
      # Non valid activities are not uploaded/created
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
