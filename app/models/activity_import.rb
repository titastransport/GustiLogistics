require "dateable"

class ActivityImport < ApplicationRecord
  include ActiveModel::Model
  include Dateable
  include Importable

  validates :file, presence: true
  attr_accessor :file

################## Validations #########################
  def valid_row?(row)
    row['Item ID'] && row['Units Sold'] &&\
      row['Beg Qty'] && row['Qty on Hand']
  end

################## Product Update #############################

  def update_product(current_product, row)
    # If there's been a purchase arrival in UAR, enroute is probably false
    current_product.enroute = false if row['Units Purc']

    current_product.current = row['Qty on Hand']
    # Not updating reorder status if product enroute, for now
    if current_product.lead_time && !current_product.enroute
      current_product.update_reorder_status 
    end

    # Used for settting up new products description for now
    current_product.description = row['Item Description']
  end
  
  def find_current_product(row)
    Product.find_by(gusti_id: row['Item ID'])
  end

  # Currently not making new products from imports, because of limited products
  # desired for now
  def create_new_product(row)
    Product.new(gusti_id: row['Item ID'], description: row['Item Description'],\
                current: row['Qty on Hand'], reorder_in: 999)
  end

##################### Activity Processing ##########################

  def same_activity_month?(activity)
    # Create datetime creates datetime from current files title date
    # This will match an activity date of the same in database
    activity.date == create_datetime
  end

  def existing_activity(product)
    product.activities.select do |activity|
      same_activity_month?(activity)
    end.first
  end

  def update_activity_sold(product, row)
    existing_activity(product).sold = row['Units Sold']
  end

  def create_activity(product, row)
    product.activities.build(sold: row['Units Sold'], date: create_datetime)
  end
  
  def process_activity(product, row)
    if existing_activity(product)
      update_activity_sold(product, row)
    else
      create_activity(product, row)
    end
  end

#######################################################################

  def process_row(row)
    current_product = find_current_product(row)
    return unless current_product.valid?

    process_activity(current_product, row)
    update_product(current_product, row)

    current_product.activities.last
  end

  # Hash[[]].transpose: transposes pairs header to 
  # corresponding rows to create key value pairs in hash
  def load_imported_activities
    spreadsheet = open_spreadsheet
    header = spreadsheet.row(1)

    activities = (2..spreadsheet.last_row).map do |i|
      current_row = Hash[[header, spreadsheet.row(i)].transpose]
      process_row(current_row) if valid_row?(current_row)
    end

    activities.compact
  end

  def imported_activities
    load_imported_activities
  end

  def save
    activities = imported_activities
    if activities.map(&:valid?).all?
      activities.each { |a| a.save! && a.product.save! }
      true
    else
      display_errors(activities)
      false
    end
  end
end
