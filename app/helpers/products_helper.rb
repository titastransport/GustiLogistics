module ProductsHelper
  def percentage(quantity, total)
    ((quantity.to_f / total) * 100).to_i + 1
  end
end
