class Product < ApplicationRecord
  include ProductsHelper
  include Dateable

  before_save { gusti_id.upcase! }
  default_scope { order(:gusti_id) }
  has_many :reorders, dependent: :destroy
  has_many :activities, dependent: :destroy
  has_many :customer_purchase_orders, dependent: :destroy
  has_many :customers, through: :customer_purchase_orders
  validates :gusti_id, presence: true,
                       uniqueness: { case_sensitive: false } 
  validates :current, presence: true

  def update_current(new_quantity)
    update_attribute(:current, new_quantity)
  end

  def update_reorder_in
    update_attribute(:reorder_in, actual_reorder_in)
  end

  def update_next_reorder_date
    update_attribute(:next_reorder_date, actual_reorder_date)
  end

    # In yday format, or integer representation of day in 365 days of year
  def cant_ship_interval
    # can't order when within a month of cant travel start
    cant_ship_start = self.cant_travel_start.yday - lead_time_days
    # in contrast, can order when within a month of a cant travel start
    cant_ship_end = self.cant_travel_end.yday - lead_time_days

    # returns range of integers as dates are reprsented by their yday
    (cant_ship_start..cant_ship_end)
  end

  def producer_cant_ship_interval?(reorder_date_yday)
    cant_ship_interval.include?(reorder_date_yday)
  end

  # In yday format, or integer representation of day in 365 days of year
  def cant_produce_interval
    cant_produce_start = self.cant_produce_start.yday - lead_time_days 
    # don't subtract lead time here like in cant_ship because production
    # affected here but not in cant ship
    cant_produce_end = self.cant_produce_end.yday

    (cant_produce_start..cant_produce_end)
  end

  def producer_cant_produce_interval?(reorder_date_yday)
    cant_produce_interval.include?(reorder_date_yday)
  end

  # First day that a product can't be ordered
  # Reorder dates will be set to this if the current day is before it
  def first_cant_order_day
    [cant_ship_interval.first, cant_produce_interval.first].min
  end

  # First day that a product can be reordered again
  # Reorder dates will be set to this if the current day is already in the
  # cant_order interval
  def last_cant_order_day
    [cant_ship_interval.end, cant_produce_interval.end].max
  end

  def current_yday_of_year
    Date.today.yday
  end

  # Both cant_ship and cant_produce interval
  def calculate_both_block_reorder_in
    if current_yday_of_year <= first_cant_order_day
      difference_in_days(first_cant_order_day, current_yday_of_year) 
    else
      difference_in_days(last_cant_order_day, current_yday_of_year)
    end
  end

  # Either cant_produce or cant_ship interval
  def calculate_block_reorder_in(interval)
    if current_yday_of_year <= interval.first
      difference_in_days(interval.first, current_yday_of_year)
    else 
      difference_in_days(interval.end, current_yday_of_year)
    end
  end

  def difference_in_days(yday1, yday2)
    (yday1 - yday2).abs 
  end

  # Normal time it takes for product to be ordered and then arrive at Gustiamo
  def normal_reorder_wait_time
    self.lead_time + self.travel_time
  end

  # Accounts for sales made in waiting period between reorder and arrival
  def inventory_adjusted_for_wait
    self.current - naive_waiting_sales
  end

  
  def expected_new_monthly_sales
    forecasting_average_sales.to_f * growth
  end

  def months_till_reorder
    inventory_adjusted_for_wait / expected_new_monthly_sales 
  end

  # Sales that occur in waiting period from time of order to receiving the order
  # physically in warehouse
  def naive_waiting_sales
    normal_reorder_wait_time * expected_new_monthly_sales 
  end

  # Happens essentially when product inventory at 2 months
  # Returns value in days
  def naive_reorder_in
    months_till_reorder * DAYS_IN_MONTH
  end

  # Checks for can't ship and/or produce interval
  def actual_reorder_in
    if double_block?(naive_reorder_date) 
      calculate_both_block_reorder_in
    elsif producer_cant_produce_interval?(naive_reorder_date) 
      calculate_block_reorder_in(cant_produce_interval)
    elsif producer_cant_ship_interval?(naive_reorder_date)
      calculate_block_reorder_in(cant_ship_interval)
    else
      naive_reorder_in
    end
  end

  # Actual dates, not ydays
  def naive_reorder_date
    Date.today + naive_reorder_in
  end

  # Actual dates, not ydays
  def actual_reorder_date
    Date.today + actual_reorder_in 
  end

  def double_block?(naive_order_date)
    producer_cant_ship_interval?(naive_reorder_date) &&\
      producer_cant_produce_interval?(naive_reorder_date)
  end

  # Not historical, but predictive
  def daily_sales
    expected_new_monthly_sales / DAYS_IN_MONTH
  end

  def next_shipment_arrives_date
    (self.next_reorder_date + normal_reorder_wait_time.months).yday
  end

  def naive_quantity
    quantity = (full_order - expected_quantity_on_date(next_shipment_arrives_date))
    # For now, if a product has a reorder date of over a year, shows 0
    quantity <= 0 ? 0 : quantity
  end

  def full_order
    (expected_new_monthly_sales * self.cover_time).to_i
  end

  def reorder_quantity
    (naive_quantity + (daily_sales * gap_days)).to_i
  end

  # Very rough estimate of reorder after next date
  # Necessary to predict if a product being ordered now will have it's next
  # reorder land in a cant order period
  def reorder_after_next_date
    if order_overdue?
      (Date.today + self.cover_time.months).yday
    else
      (self.next_reorder_date + self.cover_time.months).yday
    end
  end

  def order_overdue?
    self.reorder_in <= 0 
  end

  # Calculates gap in days between reorder_after_next for a product and next available
  # reorder day
  # Used to add extra units to next upcoming order to prevent inventory shortage
  def gap_days
    if double_block?(reorder_after_next_date)
      difference_in_days(last_cant_order_day, reorder_after_next_date)
    elsif producer_cant_produce_interval?(reorder_after_next_date) 
      difference_in_days(cant_produce_interval.end, reorder_after_next_date)
    elsif producer_cant_ship_interval?(reorder_after_next_date) 
      difference_in_days(cant_ship_interval.end, reorder_after_next_date)
    else
      0
    end 
  end

  def days_till(future_date)
    future_date - current_yday_of_year  
  end

  def expected_quantity_on_date(future_date)
    # need to raise error if date before 
    return self.current if days_till(future_date) <= 0

    expected_sales_till_date = daily_sales * days_till(future_date)
    expected_quantity = self.current - expected_sales_till_date  

    expected_quantity <= 0 ? 0 : expected_quantity 
  end

  def setup?
    !self.reorder_in.nil?
  end

  def previous_product
    Product.where(["gusti_id < ?", self.gusti_id]).last
  end

  def next_product
    Product.where(["gusti_id > ?", self.gusti_id]).first
  end

  def lead_time_days
    # lead_time will be stored as integer or string so using to_f will work
    lead_time_days = self.lead_time.to_f * DAYS_IN_MONTH
  end

  def growth
    self.growth_factor.to_f
  end

    # Sums up number of purchases for a given customer in hash
  def wholesale_customer_totals(purchases)
    totals = Hash.new(0)
    purchases.each do |purchase|
      totals[purchase.customer.name] += purchase.quantity
    end

    totals
  end

  # To remove hard coding in future for average sales over any monthly range, or
  # time for that matter
  def first_half_average_sales
    final_date = this_month_date - 1.month
    start_date = final_date - 5.months

    average_monthly_sales(start_date, final_date)
  end

  def second_half_average_sales
    final_date = this_month_date - 7.months
    start_date = final_date - 11.months

    average_monthly_sales(start_date, final_date)
  end


  def first_half_top_customers
    # start date - 5 months leads to query of last 6 months
    final_date = this_month_date - 1.month
    start_date = final_date - 6.months

    find_top_customers(start_date, final_date)
  end

  def second_half_top_customers
    # start date - 5 months leads to query of previous 6 full months
    final_date = this_month_date - 7.months
    start_date = final_date - 12.months

    find_top_customers(start_date, final_date)
  end

  def find_top_customers(start_date, final_date)
    wholesale_purchases = self.customer_purchase_orders.where(date: start_date..final_date)
    totals = wholesale_customer_totals(wholesale_purchases)
    totals['Retail'] = find_retail_total(start_date, final_date, totals)
    sort_customers(totals)
  end

  def total_units_sold(start_date, final_date)
    matching_activities = self.activities.where(date: start_date..final_date)
    matching_activities.reduce(0) { |sum, activity| sum += activity.sold }
  end

  def find_retail_total(start_date, final_date, wholesale_totals)
    total_units_sold(start_date, final_date) - total_wholesale_units_sold(wholesale_totals)
  end

  # Sorts customers by quantity bought and then reverse to have in descending order
  def sort_customers(totals)
    totals.sort_by { |_, quantity| quantity }.reverse!
  end

  def total_wholesale_units_sold(wholesale_totals)
    wholesale_totals.values.reduce(0) { |sum, quantity| sum += quantity }
  end

  # Average sales in the last N months
  # may also store this one day
  def average_monthly_sales(start_date, final_date)
    duration = months_in_interval(final_date, start_date)

    total_units_sold(start_date, final_date) / duration
  end

  def months_since_year_zero(date)
    date.year * 12 + date.month
  end

  def months_in_interval(final_date, start_date)
    months_since_year_zero(final_date) - months_since_year_zero(start_date) + 1
  end

  def this_month_date
    Date.today.beginning_of_month
  end

  def sales_this_month
    total_units_sold(this_month_date, this_month_date)
  end

  def forecasting_average_sales 
    # average sales in last 12 complete months 
    previous_month = this_month_date - 1.month
    twelve_months_ago = previous_month - 12.months 

    average_monthly_sales(twelve_months_ago, previous_month)
  end

  def display_reorder_date
    if self.next_reorder_date < Date.today
      "Overdue!"
    else
      self.next_reorder_date
    end
  end
end
