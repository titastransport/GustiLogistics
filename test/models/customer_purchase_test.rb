require 'test_helper'

class CustomerOrderPurchaseTest < ActiveSupport::TestCase
  def setup
    @product = products(:pianogrillo)
    @customer = customers(:customer1)
    @purchase = @customer.customer_purchase_orders.build(quantity:\
                          100, date: Date.today, product_id: @product.id)
  end

  test "should be valid" do
    assert @purchase.valid?
  end

  test "product id and customer id should be present" do
    @purchase.product_id = nil
    assert_not @purchase.valid?
    @purchase.product_id = @product.id

    @purchase.customer_id = nil
    assert_not @purchase.valid?

    @purchase.product_id = nil
    assert_not @purchase.valid?
  end

  test "should have one purchase per month per customer and product" do
    @purchase.save
    duplicate_purchase = @customer.customer_purchase_orders.build(quantity:\
                          @purchase.quantity, date: @purchase.date, product_id: @product.id)
    assert_not duplicate_purchase.valid?
  end
end
