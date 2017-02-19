require "dateable"

class PurchaseImport < ApplicationRecord
  include ActiveModel::Model
  include Dateable
  include ImportsHelper

  validates :file, presence: true
  attr_accessor :file
  
  # Guard against them uploading Retail Customers individually
  def wholesale_customer?(row)
    row['Customer ID'].upcase.start_with?('AAA')
  end

  def same_date?(purchase)
    purchase.date == create_datetime
  end

  def same_product?(purchase, row)
    purchase.product.gusti_id == row['Item ID']
  end

  def purchase_exists_for_month?(customer, row)
    !find_matching_purchases(customer, row).empty?
  end 

  def valid_row?(row)
    row['Name'] && row['Item ID'] && row['Qty'] &&\
      wholesale_customer?(row) && product_exists?(row)
  end

  # Helper till we figure we which products to add
  def product_exists?(row)
    !(Product.where(gusti_id: row['Item ID'].upcase).empty?)
  end

  def process_row(row)
    current_customer = Customer.find_or_create_by(name: row['Name'])

    if purchase_exists_for_month?(current_customer, row)
      update_purchase_quantity(current_customer, row)
    else
      create_purchase(row)
    end
  end

  # Check for Product exists because not using many items now 
  def load_imported_purchases
    spreadsheet = open_spreadsheet
    header = spreadsheet.row(1)

    imported_purchases = (2..spreadsheet.last_row).map do |i|
      current_row = Hash[[header, spreadsheet.row(i)].transpose]
      process_row(current_row) if valid_row?(current_row)
    end

    imported_purchases.compact
  end

  def create_purchase(row)
    customer.customer_purchase_orders.build(purchase_attributes(row))
  end

  def purchase_attributes(row)
    { quantity: row['Qty'], date: create_datetime, product_id: find_current_product(row).id }
  end

  # If not found, gets created and initialized with a current value of 0
  def find_current_product(row)
    Product.find_or_create_by(gusti_id: row['Item ID']) do |product|
      product.current = 0
    end
  end

  def update_purchase_quantity(customer, row)
    existing_purchase = find_matching_purchases(customer, row).first 
    existing_purchase.update_quantity(row['Qty'])

    existing_purchase
  end 

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

  def imported_purchases
    load_imported_purchases
  end

  def find_matching_purchases(customer, row)
    customer.customer_purchase_orders.select do |purchase|
      same_date?(purchase) && same_product?(purchase, row)
    end 
  end 
end
