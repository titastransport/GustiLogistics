class Activity < ApplicationRecord
  belongs_to :product, dependent: :destroy
  default_scope -> { order(date: :desc) }
  validates :product_id, presence: true
  validates :sold, presence: true, numericality: { only_integer: true }
  validates :date, presence: true, uniqueness: { scope: :product_id }
end
