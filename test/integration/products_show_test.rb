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

  test "should mark product as ordered standard way" do
    assert_equal true, @product.enroute do
      patch products_path, params: { enroute: true }
    end
  end

  test "should mark product as arrived standard way" do
    assert_equal true, @product.enroute do
      post products_path, params: { enroute: false }
    end
  end

  test "should mark product as ordered ajax way" do
    assert_equal true, @product.enroute do
      patch products_path, params: { enroute: true }, xhr: true
    end
  end

  test "should mark product as arrived ajax way" do
    assert_equal true, @product.enroute do
      post products_path, params: { enroute: false }, xhr: true
    end
  end
end

