require "dateable"

class ActivityImport < ApplicationRecord
  include ActiveModel::Model
  include Dateable

  validates :file, presence: true
  attr_accessor :file

  def filename
    File.basename(file.original_filename, File.extname(file.original_filename))
  end

  def save
    activities = imported_activities
    if activities.map(&:valid?).all?
     activities.each(&:save!)
     true
    else
      activities.each_with_index do |activity, index|
        activity.errors.full_messages.each do |message|
          self.errors.add :base, "Row #{index + 2}: #{message}"
        end
      end
      false
    end
  end

  def imported_activities
    load_imported_activities
  end

  def same_date?(activity)
    activity.date == create_datetime
  end

  def find_matching_activities(product)
    matching_activities = product.activities.select do |activity|
      same_date?(activity)
    end
    matching_activities
  end

  def activity_exists_for_month?(product)
    !find_matching_activities(product).empty?
  end

  def update_activity_sold(product, row)
    existing_activity = find_matching_activities(product).first 
    existing_activity.sold = row['Units Sold']
    existing_activity.save!
    existing_activity
  end

  def update_product(current_product, row)
    current_product.current = row['Qty on Hand']
    current_product.update_reorder_in
    current_product.update_next_reorder_date
  end

  def load_imported_activities
    spreadsheet = open_spreadsheet
    header = spreadsheet.row(1)
    imported_activities = (2..spreadsheet.last_row).map do |i|
      row = Hash[[header, spreadsheet.row(i)].transpose]
      if not_empty_row?(row)
        product = current_product(row)
        if product.valid?
          update_product(product, row)
          if activity_exists_for_month?(product)
            update_activity_sold(product, row)
          else
            create_activity(product, row)
          end
        end
      end
    end
    imported_activities.compact
  end

  def open_spreadsheet
    Roo::Spreadsheet.open(file.path)
  end

  def create_activity(product, row)
    product.activities.build(sold: row['Units Sold'], date: create_datetime)
  end

  def not_empty_row?(row)
    row['Item ID'].to_s != "" && !row['Units Sold'].nil?
  end

  def current_product(row)
    Product.find_by(gusti_id: row['Item ID'])
  end

  def create_new_product(row)
    Product.new(gusti_id: row['Item ID'], description: row['Item Description'], current: row['Qty on Hand'], reorder_in: 999)
  end
end
