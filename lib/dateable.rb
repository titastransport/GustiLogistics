require 'date'

module Dateable
  MATCH_MONTH = /[a-zA-Z]{3,10}/
  MATCH_YEAR = /\d{4}/
  NOT_ALL_CAPS = /[^A-Z]/
  FIRST_OF_MONTH = 1

  def parse_file_name
    # File must be seperate by _ and contain maximum UAR, month, and year..
    parts = filename.split(/_/).select { |el| el =~ NOT_ALL_CAPS }
    [get_month(parts), get_year(parts)]
  end

  def get_month(arr)
    arr.select { |el| Date::MONTHNAMES.include?(el) }.first
  end

  def get_year(arr)
    arr.select { |el| el =~ MATCH_YEAR }.first
  end

  def create_datetime
    month, year = parse_file_name
    DateTime.parse("#{FIRST_OF_MONTH}/#{month}/#{year}")
  end
end
