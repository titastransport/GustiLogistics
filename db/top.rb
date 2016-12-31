def register(customers)
  customers.sheets.each do |name|
    customers.sheet(name).each_with_index(customers: 'Name', products: 'Item ID', quantities: 'Qty') do |hash, index| 
      if hash.values.all? { |v| v.to_s != '' } && index != 0
        Purchase.create( customer: hash[:customers], product: hash[:products], quantity: hash[:quantities] )
      end
    end
  end
end
