require 'test_helper'

class ProductsHelperTest < ActionView::TestCase

  def setup
    @product = products(:faella_spaghetti) 
  end

  test "reorder in both intervals calculates right reorder in time" do
    @product.cant_travel_start.is_a? Date
  end

end
