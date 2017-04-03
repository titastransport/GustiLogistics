require "dateable"

class PurchaseImport < ApplicationRecord
  include ActiveModel::Model
  include Dateable
  include Importable

  validates :file, presence: true
  attr_accessor :file, :current_row, :current_purchase, :current_product, :current_customer

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

    # Guard against Retail
    def wholesale_customer?
      !!(current_row['Customer ID'] =~ /^AAA/i)
    end

    def correct_values_present?
      !!current_row['Name'] && !!current_row['Item ID'] && !!current_row['Qty'] 
    end

    def valid_current_row?
      correct_values_present? && wholesale_customer?
    end

    def current_purchase_attributes
      { 
        quantity: current_row['Qty'].to_i, 
        date: import_month,
        product_id: current_product.id
      }
    end

    def create_purchase
      current_customer.customer_purchase_orders.build(current_purchase_attributes)
    end

    def product_doesnt_exist?
      current_product.nil?
    end

    def process_current_row
      self.current_customer = Customer.find_or_create_by(name: current_row['Name'])
      self.current_product = Product.find_or_create_by(gusti_id: current_row['Item ID']) 
      # Purchases with products that don't exist don't get processed
      return nil if product_doesnt_exist?

      if (self.current_purchase = current_customer.purchase_for_month?(import_month, current_product.id))
        current_purchase.update_for_import(current_row['Qty'].to_i)
      else
        self.current_purchase = create_purchase
      end
    end

    def load_imported_purchases
      spreadsheet = open_spreadsheet
      header = spreadsheet.row(1)

      purchases = (2..spreadsheet.last_row).map do |i|
        self.current_row = Hash[[header, spreadsheet.row(i)].transpose]
        next unless valid_current_row?
        
        process_current_row 
        current_purchase
      end

      purchases.compact
    end

    def imported_purchases
      load_imported_purchases
    end
end
