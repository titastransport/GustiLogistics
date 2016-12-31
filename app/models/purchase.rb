class Purchase < ApplicationRecord
  validates :customer, :product, :quantity, presence: true
end
