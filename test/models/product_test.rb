require 'test_helper'

class ProductTest < ActiveSupport::TestCase

  def setup
    @product = products(:faella_spaghetti) 
  end

  test "associated activities should be destroyed" do
    @product.save
    @product.activities.create!(date: Time.now, sold: 100)
    assert_difference 'Reorder.count', -1 do
      @product.destroy
    end
  end

  test "gusti_id should be unique" do
    duplicate_product = @product.dup
    duplicate_product.gusti_id.downcase
    @product.save
    assert_not duplicate_product.valid?
  end

  test "detects can't order intervals for Faella" do
    assert @product.producer_cant_ship_interval?(Date.new(2017, 5, 15).yday)
    assert_not @product.producer_cant_produce_interval?(Date.today.yday)
    # double block
    assert @product.double_block?(Date.new(2017, 8, 15).yday)
  end

  test "detects first and last can't order days" do
    assert_equal Date.new(2017, 4, 15).yday, @product.first_cant_order_day
    assert_equal Date.new(2017, 9, 15).yday, @product.last_cant_order_day
  end

  test "lead time days calculates correctly" do
    assert_equal @product.lead_time.to_f * 30, @product.lead_time_days
  end

  test "average sales calculated correctly" do
    assert_equal 100, @product.first_half_average_sales
    assert_equal 100, @product.second_half_average_sales
    assert_equal 100, @product.forecasting_average_sales
  end

  test "expected sales" do
    assert_equal @product.forecasting_average_sales * @product.growth, @product.expected_monthly_sales
    assert_equal @product.expected_monthly_sales / 30, @product.expected_daily_sales
  end

  test "reorder in naive range" do
  end
end
