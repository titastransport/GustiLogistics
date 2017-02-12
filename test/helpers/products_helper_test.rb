require 'test_helper'

class ProductsHelperTest < ActionView::TestCase

  def setup
    @product = products(:faella_spaghetti) 
  end

  test "reorder in both intervals calculates right reorder in time" do
    reorder_date_in_both = cant_ship_interval.to_a.sample
    reorder_date_outside_both = Date.new(2017, 1, 1)
    
    @product.next_reorder_date = reorder_date_in_both
    assert_equal reorder_date_in_both.yday, proper_reorder_in
  end

end
