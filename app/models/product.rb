class Product < ApplicationRecord
  include ProductsHelper

  before_save { gusti_id.upcase! }
  default_scope { order(:gusti_id) }
  has_many :reorders, dependent: :destroy
  has_many :activities, dependent: :destroy
  has_many :customer_purchase_orders, dependent: :destroy
  validates :gusti_id, presence: true,
                       uniqueness: { case_sensitive: false } 
  validates :current, presence: true

  def update_current(new_quantity)
    update_attribute(:current, new_quantity)
  end

  def update_reorder_in
    update_attribute(:reorder_in, proper_reorder_in)
  end

  def update_next_reorder_date
    update_attribute(:next_reorder_date, update_reorder_date)
  end

  def cant_ship_interval
    # can't order when within a month of cant travel start
    cant_ship_start = self.cant_travel_start.yday - lead_time_days
    # in contrast, can order when within a month of a cant travel start
    cant_ship_end = self.cant_travel_end.yday - lead_time_days

    # returns range of integers as dates are reprsented by their yday
    (cant_ship_start..cant_ship_end)
  end

  def producer_cant_ship_block?
    cant_ship_interval.include?(self.next_reorder_date.yday)
  end

  # In yday format, or integer representation of day in 365 days of year
  def cant_produce_interval
    cant_produce_start = self.cant_produce_start.yday - lead_time_days 
    # don't subtract lead time here like in cant_ship because production
    # affected here but not in cant ship
    cant_produce_end = self.cant_produce_end.yday

    (cant_produce_start..cant_produce_end)
  end

  def producer_cant_produce_interval?
    cant_produce_interval.include?(self.next_reorder_date.yday)
  end

  def lead_time_days
    # lead_time will be stored as integer or string so using to_f will work
    lead_time_days = self.lead_time.to_f * DAYS_IN_MONTH
  end

  def growth
    self.growth_factor.to_f
  end

  # happens essentially when product inventory at 2 months
  def naive_reorder_in
    inventory_adjusted_for_wait = self.current - naive_waiting_sales

    ((inventory_adjusted_for_wait / (forecasting_average_sales *
                                     growth)) * DAYS_IN_MONTH).round(1)
  end

  def update_reorder_date
    Date.today + self.reorder_in 
  end

  def normal_order_wait_time
    self.lead_time + self.travel_time
  end

  def most_recent_activity_date
    self.activities.first.date
  end

  def most_recent_purchase_date
    self.customer_purchase_orders.first.date
  end

  # Sums up number of purchases for a given customer in hash
  def wholesale_customer_totals(purchases)
    totals = Hash.new(0)

    purchases.each do |purchase|
      totals[purchase.customer.name] += purchase.quantity
    end

    totals
  end

  def first_half_average_sales
    final_date = most_recent_activity_date
    start_date = final_date - 5.months

    average_monthly_sales(start_date, final_date)
  end

  def second_half_average_sales
    final_date = most_recent_activity_date - 6.months
    start_date = final_date - 5.months

    average_monthly_sales(start_date, final_date)
  end


  def first_half_top_customers
    # start date - 5 months leads to query of last 6 months
    final_date = most_recent_purchase_date
    start_date = final_date - 5.months

    find_top_customers(start_date, final_date)
  end

  def second_half_top_customers
    # start date - 5 months leads to query of last 6 months
    final_date = most_recent_purchase_date - 6.months
    start_date = final_date - 5.months

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

  def normal_order_wait_time
    self.lead_time + self.travel_time
  end

  def lead_time_days
    # lead_time will be stored as integer or string so using to_f will work
    lead_time_days = self.lead_time.to_f * DAYS_IN_MONTH
  end

  def months_in_interval(final_date, start_date)
    (final_date.year * 12 + final_date.month) - (start_date.year * 12 + start_date.month)
  end

  def forecasting_average_sales 
    # last 12 months used for now
    final_date = most_recent_activity_date
    start_date = final_date - 11.months 
    
    average_monthly_sales(start_date, final_date)
  end

  # Sales that occur in waiting period from time of order to receiving the order
  # physically in warehouse
  def naive_waiting_sales
    normal_order_wait_time * forecasting_average_sales * growth
  end

  def first_cant_order_day
    [cant_ship_interval.first, cant_produce_interval.first].min
  end

  def last_cant_order_day
    [cant_ship_interval.end, cant_produce_interval.end].max
  end

  def current_day_of_year
    Date.today.yday
  end

  def proper_reorder_in
    if producer_cant_ship_block? && producer_cant_produce_interval?
      if current_day_of_year <= first_cant_order_day
        first_cant_order_day - current_day_of_year 
      else
        last_cant_order_day - current_day_of_year
      end
    elsif producer_cant_produce_interval? 
      if current_day_of_year <= cant_produce_interval.first
        cant_produce_interval.first - current_day_of_year 
      else 
        cant_produce_interval.end - current_day_of_year
      end
    elsif producer_cant_ship_block? 
      if current_day_of_year <= cant_ship_interval.first
        cant_ship_interval.first - current_day_of_year 
      else 
        cant_ship_interval.end - current_day_of_year
      end
    else
      naive_reorder_in
    end
  end

  def reorder_quantity
    if producer_cant_ship_block? && producer_cant_produce_interval?
      if current_day_of_year <= first_cant_order_day
        full_order - expected_quantity_on_date(first_cant_order_day)
      else
        full_order
      end
    elsif producer_cant_produce_interval? 
      if current_day_of_year <= cant_produce_interval.first
        full_order - expected_quantity_on_date(cant_produce_interval.first)
      else 
        full_order
      end
    elsif producer_cant_ship_block? 
      if current_day_of_year <= cant_ship_interval.first
        full_order - expected_quantity_on_date(cant_ship_interval.first)
      else 
        full_order
      end
    else
      full_order
    end
  end

  def expected_quantity_on_date(date_of_year)
    # need to raise error if date before 
    days_till = date_of_year - current_day_of_year 
    return self.current if days_till <= 0

    expected_sales_till_date = forecasting_average_sales * days_till
    expected_quantity = self.current - expected_sales_till_date  

    expected_quantity <= 0 ? 0 : expected_quantity 
  end

  def full_order
    (forecasting_average_sales * growth * self.cover_time).to_i
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
end

