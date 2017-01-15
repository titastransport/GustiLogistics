require_relative 'index' 
require_relative 'top'

inv = Roo::Spreadsheet.open('Unit_Activity_2015.xlsx')

customers = Roo::Spreadsheet.open('Sold_to_Customers_2015.xlsx')

populate(inv)
register(customers)
