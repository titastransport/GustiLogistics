require 'test_helper'

class ActivityTest < ActiveSupport::TestCase

  def setup
    @product = products(:pianogrillo)
    @activity = @product.activities.build(sold: 100, date: Date.today)
  end

  test "should be valid" do
    assert @activity.valid?
  end

  test "product id should be present" do
    @activity.product_id = nil
    assert_not @activity.valid?
  end

  test "sold should be present and integer" do
    @activity.sold = nil 
    assert_not @activity.valid?
    @activity.sold = 'one hundred'
    assert_not @activity.valid?
  end

  test "product should have one activity per month" do
    @activity.save
    duplicate_activity = Activity.new(sold: @activity.sold, date: @activity.date, product_id: @activity.product_id)
    assert_not duplicate_activity.valid?
  end
end
