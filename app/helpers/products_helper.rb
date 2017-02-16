module ProductsHelper
  SIX_MONTHS = 6
  TWELVE_MONTHS = 12
  DAYS_IN_MONTH = 30

  def percentage(quantity, total)
    ((quantity.to_f / total) * 100).to_i + 1
  end
end
