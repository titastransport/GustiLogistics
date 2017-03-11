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
    self.next_reorder_date = actual_reorder_date
  end

  #################### Reorder In/Date Helpers #####################

  # growth stored in database as string, so needs to be converted to float
  def growth
    self.growth_factor.to_f
  end

# Normal time it takes for product to be ordered and then arrive at Gustiamo
  def normal_months_till_reorder_arrival
    self.lead_time + self.travel_time
  end

  # Sales that occur in waiting period from time of order to receiving the order
  # physically in warehouse
  def normal_waiting_sales
    normal_months_till_reorder_arrival * expected_monthly_sales 
  end
 
  # Adjusts for sales made in waiting period between reorder and arrival
  def inventory_adjusted_for_normal_wait
    self.current - normal_waiting_sales
  end

  def matching_activities(start_date, final_date)
    self.activities.where(date: start_date..final_date)
  end

  def total_units_sold(start_date, final_date)
    matching_activities(start_date, final_date).reduce(0) do |sum, activity| 
      sum += activity.sold
    end
  end

  def average_monthly_sales(start_date, final_date)
    total_units_sold(start_date, final_date) /
    difference_in_months(start_date, final_date)
  end

  # last 12 full months
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
    inventory_adjusted_for_normal_wait / expected_monthly_sales 
  end
  
 ################### Intervals Setups and Helper Methods ######################
  # Ydays used because year is irrelevant 
  
  # Subtracts waiting time becuase any orders must be placed before waiting time
  # would start
  def travel_block_start_yday
    (self.cant_travel_start - normal_months_till_reorder_arrival.months).yday  
  end

  def travel_block_end_yday
    (self.cant_travel_end).yday
  end

  def travel_block_interval
    (travel_block_start_yday..travel_block_end_yday)
  end

  def produce_block_start_yday
    (self.cant_produce_start - self.lead_time.months).yday
  end

  def produce_block_end_yday
    (self.cant_produce_end).yday
  end

  def produce_block_interval
    (produce_block_start_yday..produce_block_end_yday)
  end

  def yday_before_interval(blocking_interval)
    blocking_interval.first - 1
  end

  def yday_after_interval(blocking_interval)
    blocking_interval.end + 1
  end

  def in_cant_order_interval?(proposed_yday)
    travel_block_interval.include?(proposed_yday) ||
      produce_block_interval.include?(proposed_yday)
  end

  def before_blocking_interval?(blocking_interval, yday)
    yday < blocking_interval.first
  end

  ##################### Calculate Reorder Date ##########################
  def adjust_yday_for_block(blocking_interval)
    if before_blocking_interval?(blocking_interval, current_yday_of_year)
      yday_before_interval(blocking_interval)
    else
      yday_after_interval(blocking_interval)
    end
  end

  def reorder_yday_adjusted_for_block(proposed_yday)
    if travel_block_interval.include?(proposed_yday) 
      adjust_yday_for_block(travel_block_interval)
    else 
      adjust_yday_for_block(produce_block_interval)
    end
  end

  def find_reorder_yday(proposed_yday)
    if in_cant_order_interval?(proposed_yday)
        adjusted_proposed_yday = reorder_yday_adjusted_for_block(proposed_yday)
      find_reorder_yday(adjusted_proposed_yday)
    else
      proposed_yday
    end
  end

  # number of days till self's inventory will be at 2 months till depletion
  # naive, because does not account for shipping blocks
  def naive_days_till_reorder
    months_till_reorder * DAYS_IN_MONTH
  end

  def naive_reorder_date
    Date.today + naive_days_till_reorder
  end

  def days_till_reorder_yday 
    find_reorder_yday(naive_reorder_date.yday) - current_yday_of_year 
  end

  def actual_days_till_reorder
    days_till_reorder_yday + years_in_future(naive_reorder_date)
  end

  # Actual dates, not ydays
  def actual_reorder_date
    date = Date.today + actual_days_till_reorder

    # Overdue dates have a reorder date of today 
    date < Date.today ? Date.today : date
  end

  ######################### Reorder Quantity ##########################
  
  def reorder_overdue?
    self.actual_days_till_reorder < 0 
  end

  # Doesn't account for gap days
  def normal_full_order
    (expected_monthly_sales * self.cover_time).to_i
  end

  def no_shipping_blocks?
    naive_reorder_date == actual_reorder_date
  end

  def months_from_next_reorder_to_reorder_after_next
    (self.normal_months_till_reorder_arrival +
      (self.cover_time - self.normal_months_till_reorder_arrival)).months
  end
  
  # Very rough estimate of reorder after next date
  # Necessary to predict if a product being ordered now will have it's next
  # reorder land in a cant order period
  def naive_reorder_after_next_yday
   # if reorder_overdue?
   #   (Date.today + months_from_next_reorder_to_reorder_after_next).yday
   # else
    (self.actual_reorder_date + months_from_next_reorder_to_reorder_after_next).yday
   # end
  end

  def adjusted_reorder_after_next_yday(proposed_reorder_after_next_yday)
    if travel_block_interval.include?(proposed_reorder_after_next_yday) 
      adjusted_reorder_after_next_yday(yday_after_interval(travel_block_interval))
    elsif produce_block_interval.include?(proposed_reorder_after_next_yday) 
      adjusted_reorder_after_next_yday(yday_after_interval(produce_block_interval))
    else
      proposed_reorder_after_next_yday
    end
  end

  # Calculates gap in days between reorder_after_next and next available reorder day after that
  # Used to add extra units to next upcoming order to prevent inventory shortage
  # period past a product's cover time
  def gap_days(proposed_reorder_after_next_yday)
    adjusted_reorder_after_next_yday(proposed_reorder_after_next_yday) -
      proposed_reorder_after_next_yday
  end
  
  # Extract out 
  def expected_quantity_on_date(future_date)
    expected_sales_till_date = expected_daily_sales * days_till(future_date)
    expected_quantity = self.current - expected_sales_till_date  
    expected_quantity <= 0 ? 0 : expected_quantity 
  end

  # Used primarily to check if more quantity than necessary will be there on
  # next reorder date
  def next_shipment_arrives_date
    self.actual_reorder_date + normal_months_till_reorder_arrival.months
  end

  def quantity_on_next_reorder_arrival
    expected_quantity_on_date(next_shipment_arrives_date)
  end

  def naive_reorder_quantity
    # Shipping Blocks means there had to be a premature order because of actual
    # next reorder dates landing in a cant order interval
    if no_shipping_blocks?
      normal_full_order    
    else
      normal_full_order - quantity_on_next_reorder_arrival
    end
  end

  def cover_gap_days_quantity
    expected_daily_sales * gap_days(naive_reorder_after_next_yday)
  end

  # Need to augment cover_time for gap days
  def actual_reorder_quantity
    (naive_reorder_quantity + cover_gap_days_quantity).to_i
  end
 
  #######################  Customer Sales ##########################

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

  def wholesale_purchases(start_date, final_date)
    self.customer_purchase_orders.where(date: start_date..final_date)
  end

  # Sums up number of purchases for a given customer in hash
  def wholesale_customer_totals(purchases)
    totals = Hash.new(0)

    purchases.each do |purchase|
      totals[purchase.customer.name] += purchase.quantity
    end

    totals
  end

  def purchases_total(start_date, final_date)
    wholesale_customer_totals(wholesale_purchases(start_date, final_date))
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

  def find_top_customers(start_date, final_date)
    customer_totals = wholesale_customer_totals(wholesale_purchases(start_date, final_date))
    customer_totals['Retail'] = find_retail_total(start_date, final_date, customer_totals)
    sort_customers(customer_totals)
  end

  ##################### Used in Product Show View ##########################
  def previous_product
    Product.where(["gusti_id < ? AND LENGTH(producer) > 0", self.gusti_id]).last
  end

  def next_product
    Product.where(["gusti_id > ? AND LENGTH(producer) > 0", self.gusti_id]).first
  end
end
