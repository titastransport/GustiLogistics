module ReordersHelper
  def product_description(reorder)
    Product.find(reorder.product_id).description
  end
end
