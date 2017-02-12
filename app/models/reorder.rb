class Reorder < ApplicationRecord
  belongs_to :product, :dependent :destroy
  validates :product_id, presence: true
  validates :date, presence: true
  validates :quantity, presence: true
end
