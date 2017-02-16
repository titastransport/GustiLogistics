require 'test_helper'

class ProductsControllerTest < ActionDispatch::IntegrationTest

  setup do
    @user = users(:edoardo)
    log_in_as(@user)
    @product = products(:faella_spaghetti)
    @products = [@product]
  end

  test "should get index" do
    get products_url
    assert_response :success
  end

  test "should get new" do
    get new_product_url
    assert_response :success
  end

  test "should get edit" do
    get edit_product_url(@product)
    assert_response :success
  end

  test "should destroy product" do
    assert_difference('Product.count', -1) do
      delete product_url(@product)
    end

    assert_redirected_to products_url
  end
end
