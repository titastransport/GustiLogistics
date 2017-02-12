module ProductsHelper
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

  # Finds all records from an associated model between dates with current
  # product id
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

    top_customers = find_top_customers(start_date, final_date)
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

  def normal_order_wait_time
    @product.lead_time + @product.travel_time
  end

  def lead_time_days
    # lead_time will be stored as integer or string so using to_f will work
    lead_time_days = @product.lead_time.to_f * DAYS_IN_MONTH
  end

  def months_in_interval(interval)
    interval.end.month - interval.first.month
  end

  def cant_ship_interval
    # can't order when within a month of cant travel start
    cant_ship_start = @product.cant_travel_start.yday - lead_time_days
    # in contrast, can order when within a month of a cant travel start
    cant_ship_end = @product.cant_travel_end.yday - lead_time_days

    # returns range of integers as dates are reprsented by their yday
    (cant_ship_start..cant_ship_end)
  end

  def producer_cant_ship_block?
    cant_ship_interval.include?(@product.next_reorder_date.yday)
  end

  # In yday format, or integer representation of day in 365 days of year
  def cant_produce_interval
    cant_produce_start = @product.cant_produce_start.yday - lead_time_days 
    # don't subtract lead time here like in cant_ship because production
    # affected here but not in cant ship
    cant_produce_end = @product.cant_produce_end.yday

    (cant_produce_start..cant_produce_end)
  end

  def producer_cant_produce_interval?
    cant_produce_interval.include?(@product.next_reorder_date.yday)
  end

  # Sales that occur in waiting period from time of order to receiving the order
  # physically in warehouse
  def naive_waiting_sales
    normal_order_wait_time * average_monthly_sales * growth
  end

  def growth
    @product.growth_factor.to_f
  end

  # happens essentially when product inventory at 2 months
  def naive_reorder_in
    inventory_adjusted_for_wait = @product.current - naive_waiting_sales

    ((inventory_adjusted_for_wait / (average_monthly_sales *
                                     growth)) * DAYS_IN_MONTH).round(1)
  end

  def update_reorder_date
    Date.today + proper_reorder_in 
  end

  def sooner_cant_order_block
    [cant_ship_interval.first, cant_produce_interval.first].min
  end

  def proper_reorder_in
    if producer_cant_ship_block? && producer_cant_produce_interval?
      if Date.today.yday <= sooner_cant_order_block
        sooner_cant_order_block - Date.today.yday
      else
        last_block = [cant_ship_interval.end, cant_produce_interval.end].max
        last_block - Date.today.yday
      end
    elsif producer_cant_produce_interval? 
      if Date.today.yday <= cant_produce_interval.first
        cant_produce_interval.first - Date.today.yday
      else 
        cant_produce_interval.end - Date.today.yday
      end
    elsif producer_cant_ship_block? 
      if Date.today.yday <= cant_ship_interval.first
        cant_ship_interval.first - Date.today.yday
      else 
        cant_ship_interval.end - Date.today.yday
      end
    else
      naive_reorder_in
    end
  end

  def reorder_quantity
    if producer_cant_ship_block? && producer_cant_produce_interval?
      if Date.today.yday <= sooner_cant_order_block
        full_order - expected_quantity_on_date(sooner_cant_order_block)
      else
        full_order
      end
    elsif producer_cant_produce_interval? 
      if Date.today <= cant_produce_interval.first
        full_order - expected_quantity_on_date(cant_produce_interval.first)
      else 
        full_order
      end
    elsif producer_cant_ship_block? 
      if Date.today <= cant_ship_interval.first
        full_order - expected_quantity_on_date(cant_ship_interval.first)
      else 
        full_order
      end
    else
      full_order
    end
  end

  def expected_quantity_on_date(date)
    # need to raise error if date before 
    days_till = date.yday - Date.today.yday
    return @product.current if days_till <= 0

    expected_sales_till_date = average_monthly_sales * days_till
    expected_quantity = @product.current - expected_sales_till_date  

    expected_quantity <= 0 ? 0 : expected_quantity 
  end

  def full_order
    (average_monthly_sales * growth * @product.cover_time).to_i
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
