require_relative 'index' 
require_relative 'top'
require_relative 'upload_activities'

def is_hidden?(file)
  file.start_with? '.'
end

## use first sheet to initialize products with populate function
initializer = Roo::Spreadsheet.open('db/unitactivityreportfaella2015/UAR_January_2015.xlsx')
populate(initializer)

# Upload all unit activity Faell for 2016
#Dir.foreach('unitactivityreportfaella2016') do |file|
#  next if is_hidden?(file)
#  uar = Roo::Spreadsheet.open(file)
#  UnitActivity.new(file).upload_uar
#end

# Items Sold upload
customers_2015 = Roo::Spreadsheet.open('Sold_to_Customers_2015.xlsx')
register(customers_2015)
