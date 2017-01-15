# Index Inventory status page

require 'roo'

def populate(inv)
  products = []
  inv.sheet(-1).each_with_index(id: 'Item ID', desc: 'Item Description', cur: 'Qty on Hand') do |hash, index| 
    if hash[:id].to_s != "" && index != 0
      products << { item_id: hash[:id], description: hash[:desc], current: hash[:cur], reorder_in: 999 } 
    end
  end
  products
end

def output(inventory)
  inventory.each do |product|
    puts "#{product[:item_id]} #{product[:description]} #{product[:current]} #{product[:reorder_in]}"
  end
end

if __FILE__ == $0
  inv = Roo::Spreadsheet.open('inventory_2012.xlsx')
  output(populate(inv))
end
