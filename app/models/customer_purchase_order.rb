class CustomerPurchaseOrder < ApplicationRecord
  belongs_to :customer
  belongs_to :product
  validates :quantity, presence: true
  validates :date, presence: true
  validates :product_id, presence: true
  validates :customer_id, presence: true
  validates :date, presence: true, uniqueness: { scope: [:customer_id, :product_id] }
end
