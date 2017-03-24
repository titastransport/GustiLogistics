require "dateable"

class ActivityImport < ApplicationRecord
  include ActiveModel::Model
  include Dateable
  include Importable

  validates :file, presence: true
  attr_accessor :file

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

  private

  ################## Product Methods #############################
  
    def update_product(current_product, row)
      if import_for_current_month?
        # If there's been a purchase arrival in UAR, enroute is probably false
        current_product.enroute = false if row['Units Purc']
  
        current_product.current = row['Qty on Hand'] 
      end
  
      # Not updating reorder status if product enroute, for now
      # Checking for next reorder date to make sure product set up
      if current_product.next_reorder_date && !current_product.enroute
        current_product.update_reorder_status 
        # User for setting update product description for new products until all
        # products loaded
        current_product.description = row['Item Description']
      end
    end
    
    # Currently not making new products from imports, because of limited products
    # desired for now
    def create_new_product(row)
      Product.new(gusti_id: row['Item ID'],
                  description: row['Item Description'],
                  current: row['Qty on Hand'])
    end
  
  ################## Validations #########################
    def valid_row?(row)
      !!(row['Item ID'] && row['Units Sold'] &&
        row['Beg Qty'] && row['Qty on Hand'])
    end
  
  ##################### Activity Processing ##########################
  
    # Create datetime creates datetime from current files title date
    # This will compare against the activity date in database
    def same_activity_month?(activity)
      activity.date == date_from_file_title
    end
  
    def existing_activity(product)
      product.activities.find do |activity|
        same_activity_month?(activity)
      end
    end
  
    def create_activity(product, row)
      product.activities.build(sold: row['Units Sold'].to_i,
                               date: date_from_file_title,
                               purchased: row['Units Purc'].to_i)
    end
  
    def update_activity(found_activity, row)
      found_activity.sold = row['Units Sold'].to_i
      found_activity.purchased = row['Units Purc'].to_i
  
      found_activity
    end
    
    def process_activity(product, row)
      found_activity = existing_activity(product)
  
      if found_activity      
        update_activity(found_activity, row)
      else
        create_activity(product, row)
      end
    end
  
  #################### File Processing ###################################
    # Returns activity just updated or created assuming we're in the most recent month
    def process_row(row)
      current_product = Product.find_by(gusti_id: row['Item ID'])
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
        process_row(current_row) if valid_row?(current_row) && Product.exists?(current_row['Item ID']) 
      end
  
      activities.compact
    end
  
    def imported_activities
      load_imported_activities
    end
end
