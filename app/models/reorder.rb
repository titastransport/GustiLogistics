class Reorder < ApplicationRecord
  belongs_to :product
  validates :product_id, presence: true
  validates :date, presence: true
  validates :quantity, presence: true
  validates :description, presence: true
end
