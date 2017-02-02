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
    duplicate_activity = @activity.dup
    duplicate_activity.save
    assert_not duplicate_activity.valid?
    duplicate_activity.product_id = 20
    assert duplicate_activity.valid?
  end
end
