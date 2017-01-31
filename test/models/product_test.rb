require 'test_helper'

class ProductTest < ActiveSupport::TestCase

  def setup
    @product = Product.new(gusti_id: "CAF01001", description: "S/E coffee beans", current: 42)
  end

  test "associated reorders should be destroyed" do
    @product.save
    @product.reorders.create!(date: Time.now, quantity: 100, product_id: @product.id)
    assert_difference 'Reorder.count', -1 do
      @product.destroy
    end
  end
end
