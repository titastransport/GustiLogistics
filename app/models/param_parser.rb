require 'csv_parser'

class ParamParser
  PATH_TO_PARAMS = Rails.root.join('db', 'product_params.csv') 
  include Dateable
  attr_reader :parsed_csv, :params_for_products

  def initialize
    @parsed_csv = CSVParser.new(PATH_TO_PARAMS).parsed
    @params_for_products = find_params
  end

  def date_object_for_period(date_str)
    return nil if date_str == 'nil'

    month = date_str.match(/[a-z]+/i).to_s 
    day = date_str.match(/\d+/).to_s.to_i
    Date.new(Date.today.year, month_number_from(month), day)
  end

  def set_blocking_periods(prod, index)
    prod.cant_travel_start = date_object_for_period(params_for_products['cant_travel_starts'][index])
    prod.cant_travel_end = date_object_for_period(params_for_products['cant_travel_ends'][index])
    prod.cant_produce_start = date_object_for_period(params_for_products['cant_produce_starts'][index])
    prod.cant_produce_end = date_object_for_period(params_for_products['cant_produce_ends'][index])
  end

  def set_params
    Product.all.each_with_index do |prod, index|
      prod.gusti_id = valid_gusti_ids[index]
      prod.description = params_for_products['descriptions'][index]
      prod.lead_time = params_for_products['lead_times'][index].to_f
      prod.travel_time = params_for_products['travel_times'][index].to_i
      prod.cover_time = params_for_products['cover_times'][index].to_i
      prod.growth_factor = params_for_products['growth_factors'][index]
      set_blocking_periods(prod, index)
      begin
        prod.update_reorder_date
      rescue FloatDomainError
        puts "error"
      end
    end
  end

  def valid_gusti_ids
    params_for_products['gusti_ids']
  end

  def gusti_ids_in_db 
    Product.all.map { |prod| prod.gusti_id } 
  end

  def parse_times_for(param)
    params_for_products[param] 
  end

  private

    def find_params
      pairs = Hash.new { |hash, key| hash[key] = [] }

      parsed_csv.each do |row|
        row.to_h.each do |param, value|
          pairs[param.pluralize] << value  
        end
      end

      pairs
    end
end
