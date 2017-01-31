class Product < ApplicationRecord
  has_many :reorders, dependent: :destroy
  validates :gusti_id, presence: true
  validates :current, presence: true
end
