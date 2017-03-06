require_relative 'importable'

# Module used for parsing the date of uploaded excel files
# Standard format should be TYPEOFFILE_MONTH_YEAR.xlsx
# I try to account for edge cases around standard format
module Dateable
  include Importable
  MATCH_YEAR = /\d{4}/
  DAYS_IN_YEAR = 365
  DAYS_IN_MONTH = 30
  MONTHS_IN_YEAR = 12
  FIRST_OF_MONTH = 1

  # All months capitalized in an array
  def month_names
    Date::MONTHNAMES.compact
  end

  # File must be seperate by _ and contain maximum UAR, month, and year..
  def parse_file_name
    parts = filename.split(/_/)
    { month: get_month(parts), year: get_year(parts) }
  end

  def get_month(arr)
    arr.find { |el| month_names.include?(el.capitalize) }
  end

  # Assumes valid year now..what about typos?
  def get_year(arr)
    arr.find { |el| el =~ MATCH_YEAR }
  end

  def create_datetime
    month, year = parse_file_name[:month], parse_file_name[:year]
    DateTime.parse("#{FIRST_OF_MONTH}/#{month}/#{year}")
  end

  def current_yday_of_year
    Date.today.yday
  end

  def months_since_year_zero(date)
    (date.year * MONTHS_IN_YEAR) + date.month
  end

  def difference_in_months(date1, date2)
    (months_since_year_zero(date2) - months_since_year_zero(date1)).abs + 1
  end

  def this_month_date
    Date.today.beginning_of_month
  end

  # i.e., n of 1 would be the last month
  def month_back(n)
    this_month_date - n.months 
  end

  def difference_in_days(yday1, yday2)
    (yday1 - yday2).abs 
  end

 # Necessary because of inability to ignore years of dates in database when
  # calculating reorder ins with blocks
  def years_in_future(future_date)
    (future_date.year - Date.today.year) * DAYS_IN_YEAR
  end

 # Accounts for difference in years when it comes days
  def days_till(future_date)
    difference_in_days(future_date.yday, current_yday_of_year) +\
      years_in_future(future_date) 
  end
end
