class Customer < ApplicationRecord
  has_many :customer_purchase_orders, dependent: :destroy
  validates :name, presence: true, uniqueness: { case_sensitive: false }
end
