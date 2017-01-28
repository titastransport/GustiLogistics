require_relative 'index' 
require_relative 'top'

#DIR2015 = 'unitactivityreportfaella2015'
#DIR2016 = 'unitactivityreportfaella2016'
#
## use first sheet to initialize products with populate function
initializer = Roo::Spreadsheet.open('db/unitactivityreportfaella2015/UAR_January_2015.xlsx')
populate(initializer)

#Dir.foreach(DIR2015) do |file|
#  uar = Roo::Spreadsheet.open(file)
#  update_database(uar)
#end
#
#
customers_2015 = Roo::Spreadsheet.open('Sold_to_Customers_2015.xlsx')

register(customers_2015)
