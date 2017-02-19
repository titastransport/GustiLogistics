require 'date'

module Dateable
  MATCH_MONTH = /[a-zA-Z]{3,10}/
  MATCH_YEAR = /\d{4}/
  NOT_ALL_CAPS = /[^A-Z]/

  def parse_file_name
    # File must be seperate by _ and contain maximum UAR, month, and year..
    parts = filename.split(/_/).select { |el| el =~ NOT_ALL_CAPS }
    { month: get_month(parts), year: get_year(parts) }
  end

  def get_month(arr)
    arr.select { |el| Date::MONTHNAMES.include?(el) }.first
  end

  def get_year(arr)
    arr.select { |el| el =~ MATCH_YEAR }.first
  end

  # upload datetimes uses day of upload to distinguish between reports of the
  # same month
  # maybe there's way to save week of year if they continue with weekly uplaods?
  def create_datetime
    month, year = parse_file_name[:month], parse_file_name[:year]
    DateTime.parse("#{1}/#{month}/#{year}")
  end

  def current_day_of_year
    Date.today.yday
  end
end
