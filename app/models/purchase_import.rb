require "dateable"

class PurchaseImport < ApplicationRecord
  include ActiveModel::Model
  include Dateable
  include Importable

  validates :file, presence: true
  attr_accessor :file

  def save
    purchases = imported_purchases

    if purchases.map(&:valid?).all?
      purchases.each(&:save!)
      true
    else
      display_errors(purchases)
      false
    end
  end

  private

    ####################### Row Validations ######################## 
    # Guard against them uploading Retail Customers individually
    def wholesale_customer?(row)
      !!(row['Customer ID'] =~ /^AAA/i)
    end

    def correct_values_present?(row)
      row['Name'] && row['Item ID'] && row['Qty'] 
    end

    def valid_row?(row)
      correct_values_present?(row) && wholesale_customer?(row)  
    end

    ################# Purchase Processing ########################

    def same_date?(purchase)
      purchase.date == date_from_file_name(filename)
    end

    def same_product?(purchase, row)
      purchase.product.gusti_id == row['Item ID']
    end

    def current_product_id(row)
      product = Product.find_by(gusti_id: row['Item ID']) 

      product ? product.id : nil
    end

    def purchase_attributes(row)
      { 
        quantity: row['Qty'], 
        date: date_from_file_name(filename),
        product_id: current_product_id(row)
      }
    end

    def create_purchase(customer, row)
      customer.customer_purchase_orders.build(purchase_attributes(row))
    end

    def find_existing_purchase(customer, row)
      customer.customer_purchase_orders.find do |purchase|
        same_date?(purchase) && same_product?(purchase, row)
      end
    end 

###################### Main Processing #######################
  
    def current_customer(row)
      Customer.find_or_create_by(name: row['Name'])
    end

    def update_purchase(found_purchase, row)
      found_purchase.quantity = row['Qty']
      
      found_purchase
    end

    def process_row(row)
      customer = current_customer(row)
      found_purchase = find_existing_purchase(customer, row)

      if found_purchase
        update_purchase(found_purchase, row)
      else
        create_purchase(customer, row)
      end
    end

    def load_imported_purchases
      spreadsheet = open_spreadsheet
      header = spreadsheet.row(1)

      purchases = (2..spreadsheet.last_row).map do |i|
        current_row = Hash[[header, spreadsheet.row(i)].transpose]
        process_row(current_row) if valid_row?(current_row)
      end

      purchases.compact
    end

    def imported_purchases
      load_imported_purchases
    end
end
