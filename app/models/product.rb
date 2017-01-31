class Product < ApplicationRecord
  has_many :reorders, dependent: :destroy
  has_many :activities, dependent: :destroy
  validates :gusti_id, presence: true
  validates :current, presence: true

  def update_current(new_quantity)
    self.current = new_quantity 
  end
end
