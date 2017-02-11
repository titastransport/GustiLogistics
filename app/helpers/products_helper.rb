module ProductsHelper
  # start with standard 6 months as "Look back" time
  # May need to update, and may need to keep optimal lookback time for each
  # product so may need to store these values in database
  SIX_MONTHS = 6
  TWELVE_MONTHS = 12
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
  def matching_records(associated_model, start_date, final_date)
    associated_model.where(date: start_date..final_date, product_id: @product.id)
  end

  # Sums up number of purchases for a given customer in hash
  def wholesale_customer_totals(purchases)
    totals = Hash.new(0)

    purchases.each do |purchase|
      totals[purchase.customer.name] += purchase.quantity
    end

    totals
  end

  def first_half_top_customers
    # start date - 5 months leads to query of last 6 months
    final_date = most_recent_date
    start_date = final_date - 5.months

    find_top_customers(start_date, final_date)
  end

  def second_half_top_customers
    # start date - 5 months leads to query of last 6 months
    final_date = most_recent_date - 6.months
    start_date = final_date - 5.months

    find_top_customers(start_date, final_date)
  end

  def find_top_customers(start_date, final_date)
    wholesale_purchases = matching_records(CustomerPurchaseOrder, start_date, final_date)
    totals = wholesale_customer_totals(wholesale_purchases)
    totals['Retail'] = find_retail_total(start_date, final_date, totals)
    sort_customers(totals)
  end


  def total_units_sold(start_date, final_date)
    matching_activities = matching_records(Activity, start_date, final_date)
    matching_activities.reduce(0) { |sum, activity| sum += activity.sold }
  end

  def find_retail_total(start_date, final_date, wholesale_totals)
    total_units_sold(start_date, final_date) - total_wholesale_units_sold(wholesale_totals)
  end

    # Finds top n customers
  def sort_customers(totals)
    totals.sort_by { |_, quantity| quantity }.reverse!
  end

  def total_wholesale_units_sold(wholesale_totals)
    wholesale_totals.values.reduce(0) { |sum, quantity| sum += quantity }
  end

  # Average sales in the last N months
  # may also store this one day
  def average_monthly_sales
    final_date = most_recent_date
    start_date = final_date - 11.months

    total_units_sold(start_date, final_date) / TWELVE_MONTHS
  end

  def total_wait_time
    @product.lead_time + @product.travel_time
  end

  def cant_ship_interval
  # lead_time will be stored as integer or string so using to_f will work
    # regardless
    lead_time_days = @product.lead_time.to_f * DAYS_IN_MONTH

    # can't order when within a month of cant ship start
    cant_ship_start = @product.cant_travel_start.yday - lead_time_days
    # in contrast, can order when within a month of a cant ship start
    cant_ship_end = @product.cant_travel_end.yday - lead_time_days

    (cant_ship_start..cant_ship_end)
  end

  def months_in_interval(interval)
    interval.end.month - interval.first.month
  end

  def producer_cant_ship_block?
    cant_ship_interval.include?(reorder_date.yday)
  end

  # In yday format, which basically means integers
  def cant_produce_interval
    cant_produce_start = @product.cant_produce_start.yday
    cant_produce_end = @product.cant_produce_end.yday

    (cant_produce_start..cant_produce_end)
  end
  
  def producer_cant_produce_interval?
    cant_produce_interval.include?(reorder_date.yday)
  end

  # Sales that occur in waiting period from time of order to receiving the order
  # physically in warehouse
  def waiting_sales
    total_wait_time * average_monthly_sales * growth
  end

  def growth
    @product.growth_factor.to_f
  end

  # happens essentially when product inventory at 2 months
  def naive_reorder_in
    inventory_adjusted_for_wait = @product.current - waiting_sales

    ((inventory_adjusted_for_wait / (average_monthly_sales *
    growth)) * DAYS_IN_MONTH).round(1)
  end

  def update_reorder_date
    Date.today + @product.reorder_in
  end

  def proper_reorder_in
    if producer_cant_ship_block? && producer_cant_produce_interval?
      sooner = [cant_ship_interval.first, cant_produce_interval.first].min
      if Date.today.yday <= sooner
        sooner - Date.today.yday
      else
        last_block = [cant_ship_interval.end, cant_produce_interval.end].max
        last_block - Date.today.yday
      end
    elsif producer_cant_ship_block? 
      if Date.today <= cant_produce_interval.first
        cant_produce_interval.first - Date.today
      else 
        cant_produce_interval.end - Date.today
      end
    elsif producer_cant_ship_block? 
      if Date.today <= cant_ship_interval.first
        cant_ship_interval.first - Date.today
      else 
        cant_ship_interval.end - Date.today
      end
    else
      naive_reorder_in
    end
  end
  
  def naive_reorder_quantity
    ((average_monthly_sales * growth * @product.cover_time).to_i)
  end

  # temporary check if previous product setup while I fill out products
  def setup?(product)
    !product.reorder_in.nil?
  end

  def previous_product
    Product.where(["gusti_id < ?", @product.gusti_id]).last
  end

  def next_product
    Product.where(["gusti_id > ?", @product.gusti_id]).first
  end
end
