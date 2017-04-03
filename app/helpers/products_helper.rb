module ProductsHelper
  include Dateable

  def display_reorder_date
    if enroute
      "Ordered"
    elsif next_reorder_date == Date.today 
      "Today!"
    elsif in_cant_order_interval?(Date.today.yday) 
      "Cant't order period. Next calculated reorder date: #{next_reorder_date}"
    else
      next_reorder_date
    end
  end

  def sales_this_month
    total_units_sold_in_range(this_month_date, this_month_date)
  end

  def display_human_friendly_month_range(date1, date2)
    "#{english_month_name(date1)} #{date1.year} - #{english_month_name(date2)} #{date2.year}"
  end

  def last_six_full_months
    display_human_friendly_month_range(month_back(6), month_back(1))
  end

  def previous_six_full_months
    display_human_friendly_month_range(month_back(12), month_back(7))
  end

  def first_half_average_sales
    @product.send(:average_monthly_sales_in_range, month_back(6), month_back(1))
  end

  def second_half_average_sales
    @product.send(:average_monthly_sales_in_range, month_back(12), month_back(7))
  end

  def first_half_top_customers
    @product.find_top_customers_in_range(month_back(6), month_back(1))
  end

  def second_half_top_customers
    @product.find_top_customers_in_range(month_back(12), month_back(7))
  end
end
