# Module used for parsing the date of uploaded excel files
# Standard format should be TYPEOFFILE_MONTH_YEAR.xlsx
# I try to account for edge cases around standard format

module Dateable
  YEAR = /\d{4}/
  DAYS_IN_YEAR = 365
  DAYS_IN_MONTH = 30
  MONTHS_IN_YEAR = 12
  FIRST_OF_MONTH = 1
  MONTH_NAMES = Date::MONTHNAMES.compact

  def date_from_filename(filename)
    month, year = parse_filename(filename)

    Date.strptime("#{month}/#{FIRST_OF_MONTH}/#{year}", "%m/%d/%Y")
  end

  def months_to_days(months)
    (months * DAYS_IN_MONTH).to_i
  end

  def english_month_name_from(date)
    MONTH_NAMES[date.month - 1]  
  end

  def month_number_from(english_month)
    MONTH_NAMES.index(english_month) + 1
  end

  def this_month_date
    Date.today.beginning_of_month
  end

  def current_yday_of_year
    Date.today.yday
  end

  def yday_after_interval(interval)
    interval.end + 1
  end

  def difference_in_months(date1, date2)
    (months_since_year_zero(date2) - months_since_year_zero(date1)).abs + 1
  end

  def difference_in_days(yday1, yday2)
    (yday1 - yday2).abs 
  end

  # i.e., n of 1 would be the last month
  def month_back(n)
    this_month_date - n.months 
  end

  def months_since_year_zero(date)
    (date.year * MONTHS_IN_YEAR) + date.month
  end

  # Necessary because of inability to ignore years of dates in database when
  # calculating reorder ins with blocks
  def years_in_future(future_date)
    (future_date.year - Date.today.year) * DAYS_IN_YEAR
  end

  # Accounts for difference in years when it comes days
  def days_till(future_date)
    difference_in_days(future_date.yday, current_yday_of_year) + years_in_future(future_date) 
  end

  private

    def month_name_from(filename_parts)
      filename_parts.find { |el| MONTH_NAMES.include?(el.capitalize) }
    end

    def year_from(filename_parts)
      filename_parts.find { |el| el =~ YEAR }
    end

    def parse_filename(filename, delimiter='_')
      filename_parts = filename.split(delimiter)
      [ month_number_from(month_name_from(filename_parts)), year_from(filename_parts) ]
    end
end
