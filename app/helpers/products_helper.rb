module ProductsHelper
  def percentage(quantity, total)
    ((quantity.to_f / total) * 100).to_i + 1
  end

  def get_month_name(num)
    Date::MONTHNAMES[num]
  end

  # Finds last n months for a query of top customers for Product#show
  def last_n_months(most_recent_month, n) 
    months = []
    most_recent_month.downto(most_recent_month - (n - 1)) do |m|
      m += 12 if m <= 0
      months << m
    end
    months
  end

  # Finds all purchase orders within last n months and with the current product
  # id of Product#show
  # using 6 months for now, because seems like best guess for predicting, if I
  # had to choose only one, could be expanded to accept input from user
  def matching_purchases
    most_recent_month = CustomerPurchaseOrder.first.date.month
        months_to_query = last_n_months(most_recent_month, 6)
    CustomerPurchaseOrder.select do |purchase| 
      (months_to_query.include?(purchase.date.month)) && (purchase.product_id == @product.id)
    end
  end

  # Sums up total purchases for the current product for each customer
  def customer_purchases_totals
    totals = Hash.new(0)
    matching_purchases.each do |matching_purchase|
      totals[matching_purchase.customer.name] += matching_purchase.quantity
    end
    totals
  end

  # Finds top twenty customers
  def find_top_twenty_customers
    customer_purchases_totals.max_by(20) { |_, quantity| quantity } 
  end
end
