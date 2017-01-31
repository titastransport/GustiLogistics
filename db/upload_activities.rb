require 'roo'

MATCH_MONTH = /(?<=_)\w+(?=_)/
months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']

class UnitActivity
  attr_reader :file

  def initialize(file)
    @file = file
  end

  def upload_uar
    file.each_with_index(gusti_id: 'Item ID', sold: 'Units Sold') do |hash, index| 
      upload_row(hash)
    end
  end

  def upload_row(hash)
    gusti_id = hash[:gusti_id]
    if not_empty_row?(gusti_id) && !index.zero?
      product_id = Product.find_by(gusti_id: gusti_id)
      sold_this_month = hash[:sold]
      Activity.create!(product_id: product_id, sold: sold_this_month, date: Date.today.month) 
    end
  end

  def not_empty_row?(id_cell)
    id_cell.to_s != "" 
  end
end

#Dir.foreach('unitactivityreportfaella2016') do |file|
#end
