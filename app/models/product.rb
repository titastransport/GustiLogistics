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

  def update_reorder_status
    self.reorder_in = actual_reorder_in
    self.next_reorder_date = actual_reorder_date
  end


 # ######################################################################################################
  # Actual Reorder In/Date methods

  # Happens essentially when product inventory at 2 months
  # Returns value in days
  def naive_reorder_in
    months_till_reorder * DAYS_IN_MONTH
  end

  def naive_reorder_yday
    (Date.today + naive_reorder_in).yday
  end

  # Assumption: can't produce during no travel time as well
  # Interval substracts waiting time from cant_travel_start to ensure product
  # will not be traveling in cant_travel time
  # Ydays used because year is irrelevant 
  def travel_block_interval
    travel_block_start = (self.cant_travel_start - normal_reorder_wait_time.months).yday
    travel_block_end = (self.cant_travel_end).yday
    (travel_block_start..travel_block_end)
  end

  def produce_block_interval
    travel_block_start = (self.cant_produce_start - self.lead_time.months).yday
    travel_block_end = (self.cant_produce_end).yday
    (travel_block_start..travel_block_end)
  end

  def cant_order_interval?(proposed_yday)
    travel_block_interval.include?(proposed_yday) ||
      produce_block_interval.include?(proposed_yday)
  end

  def reorder_yday_adjusted_for_block(proposed_yday)
    if travel_block_interval.include?(proposed_yday) 
      if current_yday_of_year < travel_block_interval.first
        travel_block_interval.first - 1
          #+ years_in_future(naive_reorder_date)
      else 
        travel_block_interval.end + 1
        #+ years_in_future(naive_reorder_date)
      end
    elsif produce_block_interval.include?(proposed_yday) 
      if current_yday_of_year < produce_block_interval.first
        produce_block_interval.first - 1
          #+ years_in_future(naive_reorder_date)
      else 
        produce_block_interval.end + 1
        #+ years_in_future(naive_reorder_date)
      end
    end
  end

  # Checks if naive yday is valid
  # Rescursively handles any non-valid ydays based on whether they yday is in a
  # shipping cant order interval
  def find_reorder_yday(proposed_yday)
    if cant_order_interval?(proposed_yday)
      find_reorder_yday(reorder_yday_adjusted_for_block(proposed_yday))
    else
      proposed_yday
    end
  end

  def actual_reorder_in
    find_reorder_yday(naive_reorder_yday) - Date.today.yday
  end

  # Actual dates, not ydays
  def actual_reorder_date
    date = Date.today + actual_reorder_in 

    # They want all any changes to inventory that result in a need to reorder to
    # set the next reorder date to that date
    if date < Date.today
      Date.today
    else
      date
    end
  end

  ###############################################################################################
  # Methods related to ordering block intervals

  #############################################################################################
  # Reorder In/Date Helpers
  
   # lead_time will be stored as integer or string so using to_f will work
  def lead_time_days
    self.lead_time.to_f * DAYS_IN_MONTH
  end

 # Normal time it takes for product to be ordered and then arrive at Gustiamo
  def normal_reorder_wait_time
    self.lead_time + self.travel_time
  end

  def growth
    self.growth_factor.to_f
  end

  # Sales that occur in waiting period from time of order to receiving the order
  # physically in warehouse
  def naive_waiting_sales
    normal_reorder_wait_time * expected_monthly_sales 
  end
 
  # Accounts for sales made in waiting period between reorder and arrival
  def inventory_adjusted_for_wait
    self.current - naive_waiting_sales
  end

  def total_units_sold(start_date, final_date)
    matching_activities = self.activities.where(date: start_date..final_date)
    matching_activities.reduce(0) { |sum, activity| sum += activity.sold }
  end

  # Average sales in the last N months
  # may also store this one day
  def average_monthly_sales(start_date, final_date)
    total_units_sold(start_date, final_date) / difference_in_months(start_date, final_date)
  end
  # Based on last 12 full months
  def forecasting_average_sales 
    average_monthly_sales(month_back(12), month_back(1))
  end

  def expected_monthly_sales
    forecasting_average_sales.to_f * growth
  end

  def expected_daily_sales
    expected_monthly_sales / DAYS_IN_MONTH
  end

  def months_till_reorder
    inventory_adjusted_for_wait / expected_monthly_sales 
  end

  
  ############################################################################################
  # Reorder Quantity
  
  def reorder_overdue?
    self.actual_reorder_in < 0 
  end

  # Very rough estimate of reorder after next date
  # Necessary to predict if a product being ordered now will have it's next
  # reorder land in a cant order period
  def reorder_after_next_date
    if reorder_overdue?
      Date.today + self.cover_time.months
    else
      self.next_reorder_date + self.cover_time.months
    end
  end

  def no_shipping_blocks?
    naive_reorder_date == actual_reorder_date
  end

  def expected_quantity_on_date(future_date)
    # need to raise error if date before 
    return self.current if days_till(future_date) <= 0

    expected_sales_till_date = expected_daily_sales * days_till(future_date)
    expected_quantity = self.current - expected_sales_till_date  

    expected_quantity <= 0 ? 0 : expected_quantity 
  end

  # Used primarily to check if more quantity than necessary will be there on
  # next reorder date
  def next_shipment_arrives_date
    self.next_reorder_date + normal_reorder_wait_time.months
  end

  def quantity_on_reorder_arrival
    expected_quantity_on_date(next_shipment_arrives_date)
  end

    # Calculates gap in days between reorder_after_next for a product and next available
  # reorder day after that
  # Used to add extra units to next upcoming order to prevent inventory shortage
  # period past a product's cover time
  def gap_days
    if double_block?(reorder_after_next_date.yday)
      difference_in_days(last_cant_order_day, reorder_after_next_date.yday)
    elsif producer_cant_produce_interval?(reorder_after_next_date.yday) 
      difference_in_days(cant_produce_interval.end, reorder_after_next_date.yday)
    elsif producer_cant_ship_interval?(reorder_after_next_date.yday) 
      difference_in_days(cant_ship_interval.end, reorder_after_next_date.yday)
    else
      0
    end 
  end

  # Doesn't account for gap days
  def normal_full_order
    (expected_monthly_sales * self.cover_time).to_i
  end

  ###########################################################################################################
  # Actual Reorder Quantity methods

  def naive_reorder_quantity
    if no_shipping_blocks?
      normal_full_order    
    else
      normal_full_order - quantity_on_reorder_arrival
    end
  end

  # Need to augment cover_time for gap days
  def actual_reorder_quantity
    (naive_reorder_quantity + (expected_daily_sales * gap_days)).to_i
  end
 
  ###########################################################################################################
  # Customer Sales

  # Sums up number of purchases for a given customer in hash
  def wholesale_customer_totals(purchases)
    totals = Hash.new(0)

    purchases.each do |purchase|
      totals[purchase.customer.name] += purchase.quantity
    end

    totals
  end

  def first_half_average_sales
    average_monthly_sales(month_back(6), month_back(1))
  end

  def second_half_average_sales
    average_monthly_sales(month_back(12), month_back(7))
  end

  def first_half_top_customers
    find_top_customers(month_back(6), month_back(1))
  end

  def second_half_top_customers
    find_top_customers(month_back(12), month_back(7))
  end

  def purchases_total(start_date, final_date)
    wholesale_purchases = self.customer_purchase_orders.where(date: start_date..final_date)
    wholesale_customer_totals(wholesale_purchases)
  end

  def find_top_customers(start_date, final_date)
    customer_totals = purchases_total(start_date, final_date)
    customer_totals['Retail'] = find_retail_total(start_date, final_date, customer_totals)
    sort_customers(customer_totals)
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

  ######################################################################################################
  # For views

  # Temp for non-setup products in db
  # Ignores non-setup products for next/previous arrows on product#show page
  def setup?
    !self.reorder_in.nil?
  end

  def previous_product
    Product.where(["gusti_id < ?", self.gusti_id]).last
  end

  def next_product
    Product.where(["gusti_id > ?", self.gusti_id]).first
  end

  def display_reorder_date
    if self.enroute
      "Ordered"
    elsif self.next_reorder_date < Date.today 
      "Overdue!"
    elsif self.next_reorder_date == Date.today 
      "Today!"
    else
      self.next_reorder_date
    end
  end

  def sales_this_month
    total_units_sold(this_month_date, this_month_date)
  end
end
