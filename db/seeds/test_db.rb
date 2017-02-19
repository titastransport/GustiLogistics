require_relative "../../lib/dateable"
require 'roo'
include Dateable

month = {
  January:    1,
  February:   2, 
  March:      3, 
  April:      4, 
  May:        5,
  June:       6, 
  July:       7,
  August:     8,
  September:  9,
  October:    10,
  November:   11,
  December:   12
}
def valid_row?(index, hash)
  index != 0 && not_empty_row?(hash[:gusti_id])
end

def not_empty_row?(cell)
  cell.to_s != ""
end



spreadsheet = Roo::Spreadsheet.open("UAR_February_2017.xlsx")
header = spreadsheet.row(1)
imported_products = (2..spreadsheet.last_row).map do |i|
  row = Hash[[header, spreadsheet.row(i)].transpose]
  puts "empty!" if row['Item ID'].nil?
end
puts imported_products.size
