class Product < ApplicationRecord
  include ProductsHelper
  include Dateable

  before_save { gusti_id.upcase! }
  default_scope { order(:gusti_id) }

  has_many :reorders, dependent: :destroy
  has_many :activities, dependent: :destroy
  has_many :customer_purchase_orders, dependent: :destroy
  has_many :customers, through: :customer_purchase_orders

  validates :gusti_id, presence: true, uniqueness: { case_sensitive: false } 
  validates :current, numericality: { only_integer: true }
  validates :cover_time, numericality: { only_integer: true }

  scope :select_setup_products, -> { where('next_reorder_date IS NOT NULL') }

  def activity_for_month?(date)
    activities.find_by(date: date) 
  end

  def update_reorder_status
    self.next_reorder_date = actual_next_reorder_date
  end

  def self.existing_gusti_id?(gusti_id)
    !!find_by(gusti_id: gusti_id)
  end

  # Actual date, not yday
  def actual_next_reorder_date
    calculated_date = Date.today + actual_days_till_next_reorder

    # Overdue dates have a reorder date of today, as asked by Gustiamo 
    calculated_date < Date.today ? Date.today : calculated_date
  end

  def expected_quantity_on_date(future_date)
    expected_quantity = current - expected_sales_till_date(future_date)  
    expected_quantity <= 0 ? 0 : expected_quantity 
  end

  def actual_reorder_quantity
    (naive_reorder_quantity + cover_gap_days_quantity).to_i
  end
 
  def find_top_customers_in_range(start_date, final_date)
    customer_totals = wholesale_customer_totals(wholesale_purchases_in_range(start_date, final_date))
    customer_totals['Retail'] = find_retail_total_in_range(start_date, final_date, customer_totals)
    sort_customers(customer_totals)
  end

  ##################### Used in Product Show View ##########################
  #Checking for length of producer assures product is set up since producerstill set manually

  def previous_product
    Product.where(["gusti_id < ? AND LENGTH(producer) > 0", gusti_id]).last
  end

  def next_product
    Product.where(["gusti_id > ? AND LENGTH(producer) > 0", gusti_id]).first
  end

  private
    
#################### Reorder In/Date Helpers #####################

    # growth stored in database as string, so needs to be converted to float
    def expected_growth_percentage
      growth_factor.to_f
    end
  
    # naive time it takes for product to be ordered and then arrive at Gustiamo
    def naive_months_from_reorder_till_arrival
      lead_time + travel_time
    end
  
    # Sales that occur in waiting period from time of order to receiving the order physically in warehouse
    def naive_waiting_sales
      naive_months_from_reorder_till_arrival * expected_monthly_sales 
    end
   
    # Adjusts for sales made in waiting period between product reorder and reorder's arrival
    def inventory_adjusted_for_naive_wait
      adjusted = current - naive_waiting_sales

      adjusted < 0 ? 0 : adjusted
    end
  
    def activities_in_range(start_date, final_date)
      activities.where(date: start_date..final_date)
    end
  
    def total_units_sold_in_range(start_date, final_date)
      activities_in_range(start_date, final_date).reduce(0) do |sum, activity| 
        sum + activity.sold
      end
    end
  
    def average_monthly_sales_in_range(start_date, final_date)
      total_units_sold_in_range(start_date, final_date) / difference_in_months(start_date, final_date)
    end
  
    def expected_monthly_sales 
      average_monthly_sales_in_range(month_back(12), month_back(1)) * expected_growth_percentage
    end
  
    def expected_daily_sales
      expected_monthly_sales / DAYS_IN_MONTH
    end
  
    # number of days till self's inventory will be at 2 months till depletion
    # naive, because does not account for shipping blocks
    def naive_days_till_next_reorder
      inventory_adjusted_for_naive_wait / expected_daily_sales 
    end

 ################### Blocking Intervals Setups and Helper Methods ######################
 
    # Ydays used because year is irrelevant 
    
    # Subtracts waiting time becuase any orders must be placed before waiting time would start
    def travel_block_start_yday
      (cant_travel_start - naive_months_from_reorder_till_arrival.months).yday  
    end
  
    # Assumption: First day to reorder for can't travel block is last day of interval
    def travel_block_end_yday
      (cant_travel_end).yday
    end
  
    def travel_block_interval
      (travel_block_start_yday..travel_block_end_yday)
    end
    
    # Subtract time needed to produce product
    def produce_block_start_yday
      (cant_produce_start - lead_time.months).yday
    end
  
    def produce_block_end_yday
      (cant_produce_end).yday
    end
  
    def produce_block_interval
      (produce_block_start_yday..produce_block_end_yday)
    end
  
    def in_cant_order_interval?(proposed_yday)
      travel_block_interval.include?(proposed_yday) ||
        produce_block_interval.include?(proposed_yday)
    end
  
    def before_blocking_interval?(blocking_interval, yday)
      yday < blocking_interval.first
    end

##################### Calculate Reorder Date ##########################

    # Blocking interval either cant_travel or cant_produce as defined above
    def adjust_yday_for_block(blocking_interval)
      if before_blocking_interval?(blocking_interval, current_yday_of_year)
        yday_before_interval(blocking_interval)
      else
        yday_after_interval(blocking_interval)
      end
    end
  
    def next_reorder_yday_adjusted_for_block(proposed_yday)
      if travel_block_interval.include?(proposed_yday) 
        adjust_yday_for_block(travel_block_interval)
      else 
        adjust_yday_for_block(produce_block_interval)
      end
    end
  
    # Recurses until proposed_yday not cant order interval
    # Can probably change to while loop
    def find_next_reorder_yday(proposed_yday)
      if in_cant_order_interval?(proposed_yday)
        adjusted_proposed_yday = next_reorder_yday_adjusted_for_block(proposed_yday)
        find_next_reorder_yday(adjusted_proposed_yday)
      else
        proposed_yday
      end
    end
  
    def naive_next_reorder_date
      Date.today + naive_days_till_next_reorder
    end
  
    def naive_days_till_next_reorder_yday 
      find_next_reorder_yday(naive_next_reorder_date.yday) - current_yday_of_year 
    end

    def actual_days_till_next_reorder
      naive_days_till_next_reorder_yday + years_in_future(naive_next_reorder_date)
    end

###################### Reorder Quantity ##########################
    
    # Naive because doesn't account for gap days
    def naive_full_order
      (expected_monthly_sales * cover_time).to_i
    end
  
    def no_shipping_blocks?
      naive_next_reorder_date == actual_next_reorder_date
    end

    # Assumption: next reorder is happening at/around time this is calculated
    def naive_months_from_next_reorder_to_reorder_after_next
      (naive_months_from_reorder_till_arrival +
        (cover_time - naive_months_from_reorder_till_arrival)).months
    end
    
    # Very rough estimate of reorder after next yday
    # Necessary to predict if a product being ordered now will have it's next
    # reorder land in a cant order period and thus to compensate and order more
    def naive_reorder_after_next_yday
      (actual_next_reorder_date + naive_months_from_next_reorder_to_reorder_after_next).yday
    end
  
    # Also could change from recursion to while
    def adjusted_reorder_after_next_yday(proposed_reorder_after_next_yday)
      if travel_block_interval.include?(proposed_reorder_after_next_yday) 
        adjusted_reorder_after_next_yday(yday_after_interval(travel_block_interval))
      elsif produce_block_interval.include?(proposed_reorder_after_next_yday) 
        adjusted_reorder_after_next_yday(yday_after_interval(produce_block_interval))
      else
        proposed_reorder_after_next_yday
      end
    end

    def expected_sales_till_date(future_date)
      expected_daily_sales * days_till(future_date)
    end

    def next_shipment_arrives_date
      actual_next_reorder_date + naive_months_from_reorder_till_arrival.months
    end
  
    # Used in cases where a product is ordered sooner than expected because of
    # shipping block and consequently a full order isn't appropriate 
    def quantity_on_next_reorder_arrival
      expected_quantity_on_date(next_shipment_arrives_date)
    end

    def naive_reorder_quantity
      if no_shipping_blocks?
        naive_full_order    
      else
        naive_full_order - quantity_on_next_reorder_arrival
      end
    end

    # Days between naive and acutal reorder after next dates
    def gap_days(proposed_reorder_after_next_yday)
      adjusted_reorder_after_next_yday(proposed_reorder_after_next_yday) -
        proposed_reorder_after_next_yday
    end
  
    def cover_gap_days_quantity
      expected_daily_sales * gap_days(naive_reorder_after_next_yday)
    end

    #######################  Customer Sales ##########################
  
    def wholesale_purchases_in_range(start_date, final_date)
      customer_purchase_orders.includes(:customer).where(date: start_date..final_date)
    end
  
    # Sums up number of purchases for a given customer in hash
    # { customer: quantity }
    def wholesale_customer_totals(purchases)
      totals = Hash.new(0)
      purchases.each do |purchase|
        totals[purchase.customer.name] += purchase.quantity
      end
      totals
    end
  
    def total_wholesale_units_sold(wholesale_totals)
      wholesale_totals.values.reduce(0) { |sum, quantity| sum + quantity }
    end
  
    # Doesn't acctualy count up retail orders..
    # Subtract total units sold calculated from activities - total wholesale units
    # sold calculated from Items Sold to Customers
    def find_retail_total_in_range(start_date, final_date, wholesale_totals)
      total_units_sold_in_range(start_date, final_date) - total_wholesale_units_sold(wholesale_totals)
    end
  
    # Sorts customers by quantity bought and then reverse to have in descending order
    def sort_customers(totals)
      totals.sort_by { |_, quantity| quantity }.reverse!.to_h
    end
end
