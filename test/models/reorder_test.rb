require 'test_helper'

class ReorderTest < ActiveSupport::TestCase

  def setup
    @product = products(:pianogrillo)
    @reorder = @product.reorders.build(date: Time.now, quantity: 100, description: @product.item_description)
  end

  test "should be valid" do
    assert @reorder.valid?
  end

  test "product id should be present" do
    @reorder.product_id = nil
    assert_not @reorder.valid?
  end

end
