require 'test_helper'

class ProductsShowTest < ActionDispatch::IntegrationTest

  def setup
    @user = users(:edoardo)
    @product = products(:faella_spaghetti)
    @products = [@product]
  end

  test "unsuccessful view" do
    get product_path(@product)
    assert_not flash.empty?
    assert_redirected_to login_url
  end
end
