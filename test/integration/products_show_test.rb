require 'test_helper'

class ProductsShowTest < ActionDispatch::IntegrationTest

  def setup
    @user = users(:edoardo)
  end

  test "unsuccessful view" do
    get products_view
    assert_not flash.empty?
    assert_redirected_to login_url
  end

  test "successful view" do
    log_in_as(@user)
    get products_view
  end

end