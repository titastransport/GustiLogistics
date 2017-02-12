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

  def matching_records(associated_model, start_date, final_date)
    associated_model.where(date: start_date..final_date, product_id: self.id)
  end
end
