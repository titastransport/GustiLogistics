# Index Inventory status page

require 'roo'

def populate(inv)
  inv.sheet(-1).each_with_index(id: 'Item ID', desc: 'Item Description', cur: 'Qty on Hand') do |hash, index| 
    if hash[:id].to_s != "" && index != 0
      Product.create( item_id: hash[:id], item_description: hash[:desc], current: hash[:cur], reorder_in: 999) 
    end
  end
end
