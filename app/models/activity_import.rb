require "dateable"

class ActivityImport < ApplicationRecord
  include ActiveModel::Model
  include Dateable
  include ImportsHelper

  validates :file, presence: true
  attr_accessor :file

  def same_date?(activity)
    activity.date == create_datetime
  end

  def valid_row?(row)
    row['Item ID'] && row['Units Sold'] &&\
      row['Beg Qty'] && row['Qty on Hand']
  end

  def find_matching_activities(product)
    product.activities.select do |activity|
      same_date?(activity)
    end
  end

  def activity_exists_for_month?(product)
    !find_matching_activities(product).empty?
  end

  def update_activity_sold(product, row)
    existing_activity = find_matching_activities(product).first 
    existing_activity.update_sold(row['Units Sold'])

    # Must return activity for map method, instead of true from update
    existing_activity
  end

  def update_product(current_product, row)
    # If there's been a purchase in UAR, enroute is probably false
    current_product.update_attribute(:enroute, false) if row['Units Purc']
    current_product.update_attribute(:current, row['Qty on Hand'])
    current_product.update_reorder_status

    # Must return activity for map method, instead of true from update
    current_product.activities.first
  end

  def process_activity(row, product)
    if activity_exists_for_month?(product)
      update_activity_sold(product, row)
    else
      create_activity(product, row)
    end
  end

  def process_product(row, product)
    process_activity(row, product)
    # product updated after new activity
    update_product(product, row)
  end

  def process_row(row)
    current_product = current_product(row)
    return unless current_product.valid?

    process_product(row, current_product)
  end

  # Hash[[]].transpose: transposes pairs header to 
  # corresponding rows to create key value pairs in hash
  def load_imported_activities
    spreadsheet = open_spreadsheet
    header = spreadsheet.row(1)

    imported_activities = (2..spreadsheet.last_row).map do |i|
      current_row = Hash[[header, spreadsheet.row(i)].transpose]
      process_row(current_row) if valid_row?(current_row)
    end

    imported_activities.compact
  end

  def create_activity(product, row)
    product.activities.build(sold: row['Units Sold'], date: create_datetime)
  end

  def current_product(row)
    Product.find_by(gusti_id: row['Item ID'])
  end

  # Currently not making new products from imports, because of limited products
  # desired for now
  def create_new_product(row)
    Product.new(gusti_id: row['Item ID'], description: row['Item Description'],\
                current: row['Qty on Hand'], reorder_in: 999)
  end

  def save
    activities = imported_activities
    if activities.map(&:valid?).all?
      activities.each(&:save!)
      true
    else
      display_errors(activities)
      false
    end
  end

  def imported_activities
    load_imported_activities
  end
end
