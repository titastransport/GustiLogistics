module ProductsHelper
  include Dateable

  def display_reorder_date
    if enroute
      "Ordered"
    elsif next_reorder_date < Date.today 
      "Overdue!"
    elsif next_reorder_date == Date.today 
      "Today!"
    else
      next_reorder_date
    end
  end

  def sales_this_month
    total_units_sold_in_range(this_month_date, this_month_date)
  end

  def percentage(quantity, total)
    ((quantity.to_f / total) * 100).to_i + 1
  end

  def last_six_full_months
    beg_month = month_names[month_back(6).month - 1]
    beg_year = month_back(6).year

    final_month = month_names[month_back(1).month - 1]
    final_year = month_back(1).year

    "#{beg_month} #{beg_year} - #{final_month} #{final_year}"
  end

  def previous_six_full_months
    beg_month = month_names[month_back(12).month - 1]
    beg_year = month_back(12).year

    final_month = month_names[month_back(7).month - 1]
    final_year = month_back(7).year

    "#{beg_month} #{beg_year} - #{final_month} #{final_year}"
  end
end
