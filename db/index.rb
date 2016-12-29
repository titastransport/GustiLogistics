# Index Inventory status page

require 'roo'

def populate(inv, inventory)
  inv.sheet(-1).each_with_index(id: 'Item ID', desc: 'Item Description', cur: 'Qty on Hand') do |hash, index| 
    inventory[:ids] << hash[:id] if hash[:id].to_s != "" && index != 0
    inventory[:descriptions] << hash[:desc] if hash[:id].to_s != "" && index != 0
    inventory[:curs] << hash[:cur].to_i if hash[:id].to_s != "" && index != 0
    inventory[:reorder_by] << 999
    # calculate(inventory[:reorder_by])
  end
end

def output(inventory)
  0.upto(inventory[:ids].size - 1) do |i|
    puts "#{inventory[:ids][i]} #{inventory[:descriptions][i]} #{inventory[:curs][i]} #{inventory[:reorder_by][i]}"
  end
end

def seed(inventory)
  0.upto(inventory[:ids].size - 1) do |i|
    Product.create( item_id: inventory[:ids][i], description: inventory[:descriptions][i], current: inventory[:curs][i], reorder_in: inventory[:reorder_by][i])
  end
end

def update(inv, inventory)
  # find new products
  # update current quantities
end

if __FILE__ == $0
  inv = Roo::Spreadsheet.open('inventory_2012.xlsx')

  inventory = {
    ids: [],
    descriptions: [], 
    curs: [],
    reorder_by: []
  }

  populate(inv, inventory)
  # output(inventory)

end
