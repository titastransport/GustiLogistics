def register(customers)
  customers.sheets.each do |name|
    customers.sheet(name).each_with_index(customers: 'Name', products: 'Item ID', quantities: 'Qty') do |hash, index| 
      if hash[:quantities].to_s != "" && index != 0 && hash[:products].to_s != "" 
        Purchase.create( customer: hash[:customers], product: hash[:products], quantity: hash[:quantities].to_i )
      end
    end
  end
end

def output(purchases)
  0.upto(purchases[:customers].size - 1) do |i|
    puts "#{purchases[:customers][i]} #{purchases[:products][i]} #{purchases[:quantities][i]}"
  end
end
