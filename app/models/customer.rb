class Customer < ApplicationRecord
  has_many :customer_purchase_orders, dependent: :destroy
  has_many :products, through: :customer_purchase_orders
  validates :name, presence: true, uniqueness: { case_sensitive: false }

  def purchase_for_month?(date, product_id)
    customer_purchase_orders.find_by(date: date, product_id: product_id) 
  end
end
