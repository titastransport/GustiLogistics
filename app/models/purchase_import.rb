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
      row['Customer ID'].upcase.start_with?('AAA')
    end

    def valid_row?(row)
      row['Name'] && row['Item ID'] && row['Qty'] &&\
        wholesale_customer?(row) && Product.exists?(row['Item ID'])
    end

    ################# Purchase Processing ########################
    #

    def create_new_product

    end

    def same_date?(purchase)
      purchase.date == date_from_file_title
    end

    def same_product?(purchase, row)
      purchase.product.gusti_id == row['Item ID']
    end

    def purchase_attributes(row)
      { 
        quantity: row['Qty'], 
        date: date_from_file_title,
        product_id: Product.find_by(gusti_id: row['Item ID']).id 
      }
    end

    def create_purchase(customer, row)
      customer.customer_purchase_orders.build(purchase_attributes(row))
    end

    def existing_purchase(customer, row)
      customer.customer_purchase_orders.select do |purchase|
        same_date?(purchase) && same_product?(purchase, row)
      end.first
    end 

###################### Main Processing #######################
  
    def current_customer(row)
      Customer.find_or_create_by(name: row['Name'])
    end

    def process_row(row)
      customer = current_customer(row)

      new_purchase = create_purchase(customer, row)

      # this checks also if purchase already exists
      if new_purchase.valid?
        new_purchase
      else
        purchase_to_update = existing_purchase(customer, row)
        purchase_to_update.quantity = row['Qty']
        purchase_to_update
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
