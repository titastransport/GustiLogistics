class ActivityImport < ApplicationRecord
  include ActiveModel::Model
  include Dateable
  include Importable

  validates :file, presence: true
  attr_accessor :file, :current_row, :current_product, :current_activity

  def save
    activities = imported_activities
    if activities.map(&:valid?).all?
      activities.each { |activity| save_all_data_from(activity) } 
      true
    else
      display_errors(activities)
      false
    end
  end

  private

    def save_all_data_from(activity)
      activity.save!
      activity.product.save! 
      activity.product.update_reorder_date
    end

    def update_current_product
      current_product.enroute = false if current_row['Units Purc'].to_i 
      current_product.current = current_row['Qty on Hand'].to_i 
    end

    def gusti_id_present?
      !!current_row['Item ID']
    end

    def current_activity_params
      {
        sold: current_row['Units Sold'].to_i,
        date: import_month,
        purchased: current_row['Units Purc'].to_i
      }
    end

    def create_activity
      current_product.activities.build(current_activity_params)
    end
  
    def process_current_activity
      if (self.current_activity = current_product.activity_for_month?(import_month))  
        current_activity.update_for_import(current_row['Units Sold'].to_i, current_row['Units Purc'].to_i)
      else
        self.current_activity = create_activity
      end
    end

    def product_doesnt_exist?
      current_product.nil?
    end
  
    def process_current_row
      self.current_product = Product.find_by(gusti_id: current_row['Item ID'])
      
      # Activities with products that don't exist don't get processed
      return nil if product_doesnt_exist? 

      process_current_activity 
      update_current_product
    end
  
    # Hash[[]].transpose: pairs header to corresponding rows to create hash
    def load_imported_activities
      spreadsheet = open_spreadsheet
      header = spreadsheet.row(1)
  
      activities = (2..spreadsheet.last_row).map do |i|
        self.current_row = Hash[[header, spreadsheet.row(i)].transpose]
        next unless gusti_id_present?

        process_current_row
        current_activity
      end
  
      activities.compact
    end
  
    def imported_activities
      load_imported_activities
    end
end
