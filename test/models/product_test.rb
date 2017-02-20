require 'test_helper'

class ProductTest < ActiveSupport::TestCase

  def setup
    @product = products(:faella_spaghetti) 
    @product2 = products(:pianogrillo)
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
    assert_equal @product.forecasting_average_sales * @product.growth,\
                 @product.expected_monthly_sales

    assert_equal @product.expected_monthly_sales / 30, @product.expected_daily_sales
  end

  test "reorder in actual accounts for different years" do
    assert_equal (Date.today + 1.year).year, @product.actual_reorder_date.year 
  end

  test "reorder in correctly calculates next reorder in for this year" do
    assert_equal @product2.cant_travel_start - 1.month, @product2.actual_reorder_date
  end

  test "days till works for this year" do
    assert_equal 10, @product.days_till(Date.today + 10.days)
  end

  test "days till works for next year" do
    assert_equal 370, @product.days_till(Date.today + 1.year + 5.days)
  end

  test "gap days finds dif in calculated reorder date and next possible reorder date" do
    assert_equal 31, @product2.gap_days
  end

  test "expected quantity on date finds proper quanties for this year" do
    future_date = Date.today + 2.months
    assert_equal 1764, @product.expected_quantity_on_date(future_date)
  end

  test "expected quantity on date finds proper quanties for next year" do
    future_date = Date.today + 1.year
    assert_equal 540, @product.expected_quantity_on_date(future_date)
  end

  test "month back finds n months back" do
    assert_equal Date.today.beginning_of_month - 2.months, @product.month_back(2)
    assert_equal Date.today.beginning_of_month - 13.months, @product.month_back(13)
  end
end
