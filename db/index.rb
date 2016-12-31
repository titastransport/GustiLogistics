# Index Inventory status page

require 'roo'

def populate(inv)
  inv.sheet(-1).each_with_index(id: 'Item ID', desc: 'Item Description', cur: 'Qty on Hand') do |hash, index| 
    if hash[:id].to_s != "" && index != 0
      Product.create( item_id: hash[:id], description: hash[:desc], current: hash[:cur], reorder_in: 999) 
    end
  end
end

def output(inventory)
  0.upto(inventory[:ids].size - 1) do |i|
    puts "#{inventory[:ids][i]} #{inventory[:descriptions][i]} #{inventory[:curs][i]} #{inventory[:reorder_by][i]}"
  end
end

if __FILE__ == $0

  inv = Roo::Spreadsheet.open('inventory_2012.xlsx')
  output(populate(inv))
end

#def update(inv, inventory)
  # find new products
  # update current quantities
#end
