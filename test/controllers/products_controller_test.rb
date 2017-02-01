require 'test_helper'

class ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:edoardo)
    @product = products(:pianogrillo)
    log_in_as(@user)
  end

  test "should get index" do
    get products_url
    assert_response :success
  end

  test "should get new" do
    get new_product_url
    assert_response :success
  end

  test "should create product" do
    assert_difference('Product.count') do
      post products_url, params: { product: { current: @product.current, description: @product.description, gusti_id: @product.gusti_id, reorder_in: @product.reorder_in } }
    end

    assert_redirected_to product_url(Product.find(3))
  end

  test "should show product" do
    get product_url(@product)
    assert_response :success
  end

  test "should get edit" do
    get edit_product_url(@product)
    assert_response :success
  end

  test "should update product" do
    patch product_url(@product), params: { product: { current: @product.current, description: @product.description, gusti_id: @product.gusti_id, reorder_in: @product.reorder_in } }
    assert_redirected_to product_url(@product)
  end

  test "should destroy product" do
    assert_difference('Product.count', -1) do
      delete product_url(@product)
    end

    assert_redirected_to products_url
  end
end
