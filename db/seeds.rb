require_relative 'index' 
require_relative 'top'

inv = Roo::Spreadsheet.open('inventory_2012.xlsx')

customers1 = Roo::Spreadsheet.open('Items Sold to customers 2012 jan thru may.xlsx')
customers2 = Roo::Spreadsheet.open('Items Sold to customers 2012 june thru dec.xlsx')

populate(inv)
register(customers1)
register(customers2)
