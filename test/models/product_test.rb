require 'test_helper'

class ProductTest < ActiveSupport::TestCase
  include Dateable

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
    assert @product.in_cant_order_interval?(Date.new(2017, 5, 15).yday)
    assert_not @product.in_cant_order_interval?(Date.new(2017, 1, 15))
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
    normal_wait_months = (@product.lead_time + @product.travel_time).months
    assert_equal @product2.cant_travel_start - normal_wait_months - 1.day, @product2.actual_reorder_date
  end

  test "days till works for this year" do
    date = Date.today + 10.days
    assert_equal 10, @product.days_till(date)
  end

  test "days till works for next year" do
    date = Date.today + 1.year + 5.days
    assert_equal 370, @product.days_till(date)
  end

  test "gap days finds dif in calculated reorder date and next possible reorder date" do
    assert_equal 47, @product2.gap_days(@product2.naive_reorder_after_next_yday)
  end

  test "expected quantity on date finds proper quanties for this year" do
    date = Date.today + 2.months
    sales = @product.expected_daily_sales * days_till(date)
    quantity = @product.current - sales
    assert_equal quantity, @product.expected_quantity_on_date(date)
  end

  test "expected quantity on date finds proper quanties for next year" do
    date = Date.today + 1.year
    assert_equal 540, @product.expected_quantity_on_date(date)
  end

  test "month back finds n months back" do
    assert_equal Date.today.beginning_of_month - 2.months, @product.month_back(2)
    assert_equal Date.today.beginning_of_month - 13.months, @product.month_back(13)
  end
end
