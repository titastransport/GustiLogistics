require "dateable"

class ActivityImport < ApplicationRecord
  include ActiveModel::Model
  include Dateable
  include Importable

  validates :file, presence: true
  attr_accessor :file

################## Validations #########################
  def valid_row?(row)
    !!(row['Item ID'] && row['Units Sold'] &&
      row['Beg Qty'] && row['Qty on Hand'])
  end

  # Used till all products are decided and setup
  def product_exists?(row)
    !(find_current_product(row).nil?)
  end

################## Product Methods #############################

  def update_product(current_product, row)
    # If there's been a purchase arrival in UAR, enroute is probably false
    current_product.enroute = false if row['Units Purc']

    current_product.current = row['Qty on Hand']
    # Not updating reorder status if product enroute, for now
    # Checking for producer to make sure product set up
    if current_product.setup? && !current_product.enroute
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
    Product.new(gusti_id: row['Item ID'],
                description: row['Item Description'],
                current: row['Qty on Hand'])
  end

##################### Activity Processing ##########################

  # Create datetime creates datetime from current files title date
  # This will compare against the activity date in database
  def same_activity_month?(activity)
    activity.date == create_datetime
  end

  def existing_activity(product)
    product.activities.find do |activity|
      same_activity_month?(activity)
    end
  end

  def create_activity(product, row)
    product.activities.build(sold: row['Units Sold'].to_i,
                             date: create_datetime,
                             purchased: row['Units Purc'].to_i)
  end
  
  def process_activity(product, row)
    found_activity = existing_activity(product)

    if found_activity      
       found_activity.sold = row['Units Sold'].to_i
       found_activity.purchased = row['Units Purc'].to_i
       found_activity
    else
      create_activity(product, row)
    end
  end

#################### File Processing ###################################
  # Returns activity just updated or created assuming we're in the most recent month
  def process_row(row)
    current_product = find_current_product(row)
    return unless current_product.valid?

    processed_activity = process_activity(current_product, row)
    update_product(current_product, row)
  
    processed_activity
  end

  # Hash[[]].transpose: transposes pairs header to 
  # corresponding rows to create key value pairs in hash
  def load_imported_activities
    spreadsheet = open_spreadsheet
    header = spreadsheet.row(1)

    activities = (2..spreadsheet.last_row).map do |i|
      current_row = Hash[[header, spreadsheet.row(i)].transpose]
      process_row(current_row) if valid_row?(current_row) && product_exists?(current_row)
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
