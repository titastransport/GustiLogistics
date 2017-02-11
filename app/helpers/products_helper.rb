module ProductsHelper
  # start with standard 6 months as "Look back" time
  # May need to update, and may need to keep optimal lookback time for each
  # product so may need to store these values in database
  SIX_MONTHS_BACK = 6
  TWELVE_MONTHS_BACK = 12
  DAYS_IN_MONTH = 30

  def percentage(quantity, total)
    ((quantity.to_f / total) * 100).to_i + 1
  end

  def get_month_name(num)
    Date::MONTHNAMES[num]
  end

  def most_recent_date
    Activity.first.date
  end

  # Find all records from last N months from the model associated with Product
  # Need to find last 12 months and then do first half in one table and second
  # half in another table
  # Choosing to get all last 12 months and then divide into last six months
  # and previous six months, because I'm assuming it's more efficient this way
  # to go into database only once

  ## works
  def matching_records(associated_model, months_back)
    # set this local variable to avoid entering database each time
    most_recent = most_recent_date
    associated_model.select do |record|
      if months_back == 12
        in_last_twelve_months?(most_recent, record) && current_product?(record)
      elsif months_back == 6
        in_last_six_months?(most_recent, record) && current_product?(record)
      end
    end
  end

  def current_product?(record)
    @product.id == record.product_id
  end

  def in_last_twelve_months?(most_recent, record) 
    record.date > most_recent - 12.months 
    #most_recent.downto((most_recent - 12.months)).include?(record.date)
  end
  
  def in_last_six_months?(most_recent, record) 
    record.date > most_recent - 6.months 
   # most_recent.downto((most_recent - 6.months)).include?(record.date)
  end

  # Splits the last year in orders into the first six and last six 
  def partition_matching_yearly_records(associated_model)
    most_recent = most_recent_date
    matching_records(associated_model, 12).partition do |purchase|
      in_last_six_months?(most_recent, purchase)
    end
  end

  # Sums up total purchases for the current product for each customer
  # 6 months choosen for default for now
  def wholesale_customer_totals
    halves = {}

    first_half = Hash.new(0)
    last_half = Hash.new(0)

    first_six, last_six = partition_matching_yearly_records(CustomerPurchaseOrder)

    first_six.each do |purchase|
      #if matching_purchase.date.month
      first_half[purchase.customer.name] += purchase.quantity
    end

    last_six.each do |purchase|
      #if matching_purchase.date.month
      last_half[purchase.customer.name] += purchase.quantity
    end

    halves[:first_half] = first_half 
    halves[:last_half] = last_half 
    halves
  end

  # Sum up total number of units sold for a given product over a specified
  # timespan
  def total_units_sold
    halves_totals = {}

    first_six, last_six = partition_matching_records(Activity)
    
    halves[first_half] = first_six.reduce(0) { |sum, activity| sum += activity.sold }
    halves[last_half] = last_six.reduce(0) { |sum, activity| sum += activity.sold }
   
    halves_totals
  end

  # Average sales in the last N months
  # may also store this one day
  def yearly_historical_monthly_product_sales
    total_units_sold.reduce(0) { |sum, half| sum += half } / TWELVE_MONTHS_BACK
  end

  # Sales that occur in waiting period from time of order to receiving the order
  # physically in warehouse
  def waiting_sales
    (@product.lead_time + @product.travel_time) * (yearly_historical_monthly_product_sales * @product.growth_factor.to_f)
  end

  # Does not account for cant_travel and cant_produce times
  # works because I take waiting time sales out
  # happens essentially when product inventory at 2 months
  def naive_reorder_in
    (((@product.current - waiting_sales) / (historical_monthly_product_sales *
    @product.growth_factor.to_f)) * DAYS_IN_MONTH).round(1)
  end

  def reorder_date
    Date.today + @product.reorder_in
  end

  def reorder_quantity
    ((historical_monthly_product_sales * @product.growth_factor.to_f * @product.cover_time).to_i)
  end

  # Finds top n customers
  def find_top_customers(num_customers)
    halves = {}

    first_half = customer_purchases_total[:first_half].max_by(num_customers) { |_, quantity| quantity }.to_h
    second_half = customer_purchases_total[:second_half].max_by(num_customers) { |_, quantity| quantity }.to_h

    halves[:first_half] = first_half 
    halves[:last_half] = last_half 
    halves
  end

  def total_wholesale_units_sold(months_back)
  # all orders, need to get more precise
    wholesale_orders = @product.customer_purchase_orders
    all_wholesales = find_top_customers(wholesale_orders.size)

    first_half_total = all_wholesales[:first_half].reduce(0) do |sum, (customer, quantity)| 
      sum += quantity
    end

    second_half_total = all_wholesales[:second_half].reduce(0) do |sum, (customer, quantity)| 
      sum += quantity
    end
    {first_half_total: first_half_total, second_half_total: second_half_total}
  end

  def total_retail_units_sold
    first_half_total = total_units_sold[:first_half] - total_wholesale_units_sold[:first_half]
    second_half_total = total_units_sold[:second_half] - total_wholesale_units_sold[:second_half]
    {first_half_total: first_half_total, second_half_total: second_half_total}
  end
end
