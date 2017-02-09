module ProductsHelper
  # start with standard 6 months as "Look back" time
  # May need to update, and may need to keep optimal lookback time for each
  # product so may need to store these values in database
  MONTHS_BACK = 6

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

  # Find all records from last N months from the model associated with Product
  def matching_records(associated_model, months_back)
    most_recent_month = associated_model.first.date.month
        months_to_query = last_n_months(most_recent_month, months_back)
    associated_model.select do |record|
      (months_to_query.include?(record.date.month)) && (record.product_id == @product.id)
    end
  end

  # Sums up total purchases for the current product for each customer
  # 6 months choosen for default for now
  def customer_purchases_totals
    totals = Hash.new(0)
    matching_records(CustomerPurchaseOrder, 6).each do |matching_purchase|
      totals[matching_purchase.customer.name] += matching_purchase.quantity
    end
    totals
  end

  # Sum up total number of units sold for a given product over a specified
  # timespan
  def total_units_sold
    matching_records(Activity, MONTHS_BACK).reduce(0) { |sum, activity| sum += activity.sold }
  end

  # Average sales in the last N months
  # may also store this one day
  def monthly_product_sales
    total_units_sold / MONTHS_BACK
  end

  # Sales that occur in waiting period from time of order to receiving the order
  # physically in warehouse
  def waiting_sales
    (@product.lead_time + @product.travel_time) * monthly_product_sales
  end

  # Does not account for cant_travel and cant_produce times
  def naive_reorder_in
    (((@product.current - waiting_sales) / \
     (monthly_product_sales * @product.growth_factor.to_f)) * 30).round(1)
  end

  def reorder_date
    @product.reorder_in + Date.today
  end

  def reorder_quantity
    (monthly_product_sales * @product.growth_factor.to_f * @product.cover_time).to_i
  end

  # Finds top twenty customers
  def find_top_twenty_customers
    customer_purchases_totals.max_by(20) { |_, quantity| quantity }
  end
end
