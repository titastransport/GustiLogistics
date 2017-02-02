class Product < ApplicationRecord
  before_save { gusti_id.upcase! }
  default_scope { order(:gusti_id) }
  has_many :reorders, dependent: :destroy
  has_many :activities, dependent: :destroy
  validates :gusti_id, presence: true,
                       uniqueness: { case_sensitive: false } 
  validates :current, presence: true

  def update_current(new_quantity)
    update_attribute(:current, new_quantity)
  end

  def update_reorder_in(days)
    update_attribute(:reorder_in, days)
  end
end
