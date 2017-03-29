class Activity < ApplicationRecord
  belongs_to :product
  default_scope -> { order(date: :desc) }
  validates :product_id, presence: true
  validates :sold, presence: true, numericality: { only_integer: true }
  validates :date, presence: true, uniqueness: { scope: :product_id }

  def update_for_import(new_sold, new_purchased)
    self.sold = new_sold
    self.purchased = new_purchased
  end
end
