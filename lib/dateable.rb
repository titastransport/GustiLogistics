require 'date'

# Module used for parsing the date of uploaded excel files
# Standard format should be TYPEOFFILE_MONTH_YEAR.xlsx
# I try to account for edge cases around standard format
module Dateable
  MATCH_YEAR = /\d{4}/

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

  def get_year(arr)
    arr.find { |el| el =~ MATCH_YEAR }
  end

  def create_datetime
    month, year = parse_file_name[:month], parse_file_name[:year]
    DateTime.parse("#{1}/#{month}/#{year}")
  end

  def current_day_of_year
    Date.today.yday
  end
end
