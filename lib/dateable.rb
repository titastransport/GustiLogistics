# Module used for parsing the date of uploaded excel files
# Standard format should be TYPEOFFILE_MONTH_YEAR.xlsx
# I try to account for edge cases around standard format

module Dateable
  YEAR = /\d{4}/
  DAYS_IN_YEAR = 365
  DAYS_IN_MONTH = 30
  MONTHS_IN_YEAR = 12
  FIRST_OF_MONTH = 1

  def yday_before_interval(interval)
    interval.first - 1
  end

  def yday_after_interval(interval)
    interval.end + 1
  end

  # All months capitalized in an array
  def month_names
    Date::MONTHNAMES.compact
  end

  def english_month_name(date)
    month_names[date.month - 1]  
  end

  def date_from_file_name(file_name)
    month, year = parse_file_name(file_name)

    Date.strptime("#{month}/#{FIRST_OF_MONTH}/#{year}", "%m/%d/%Y")
  end

  def difference_in_months(date1, date2)
    (months_since_year_zero(date2) - months_since_year_zero(date1)).abs + 1
  end

  def difference_in_days(yday1, yday2)
    (yday1 - yday2).abs 
  end

  def this_month_date
    Date.today.beginning_of_month
  end

  def import_for_current_month?
    date_from_file_name(filename) == this_month_date
  end

  def current_yday_of_year
    Date.today.yday
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
    difference_in_days(future_date.yday, current_yday_of_year) +\
      years_in_future(future_date) 
  end

  private

    def month_name(file_title_arr)
      file_title_arr.find { |el| month_names.include?(el.capitalize) }
    end

    def get_month_number(file_title_arr)
      month_names.index(month_name(file_title_arr)) + 1
    end

    def strip_out_year(str)
      str.match(YEAR).to_s
    end

    # Assumes valid year now..what about typos?
    def get_year(file_title_arr)
      year_string = file_title_arr.find { |el| el =~ YEAR }
      strip_out_year(year_string)
    end

    # File seperated by _ 
    def parse_file_name(file_name, delimiter='_')
      parts = file_name.split(/#{delimiter}/)
      [ get_month_number(parts), get_year(parts) ]
    end
end
