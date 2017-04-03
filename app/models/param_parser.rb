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

  def set_blocking_periods(prod)
    prod.cant_travel_start = date_object_for_period(params_for_products[prod.gusti_id]['cant_travel_start'])
    prod.cant_travel_end = date_object_for_period(params_for_products[prod.gusti_id]['cant_travel_end'])
    prod.cant_produce_start = date_object_for_period(params_for_products[prod.gusti_id]['cant_produce_start'])
    prod.cant_produce_end = date_object_for_period(params_for_products[prod.gusti_id]['cant_produce_end'])
  end

  def set_params
    Product.all.each do |prod|
      prod.description = params_for_products[prod.gusti_id]['description']
      prod.lead_time = params_for_products[prod.gusti_id]['lead_time']
      prod.travel_time = params_for_products[prod.gusti_id]['travel_time'].to_i
      prod.cover_time = params_for_products[prod.gusti_id]['cover_time'].to_i
      prod.growth_factor = params_for_products[prod.gusti_id]['growth_factor']
      set_blocking_periods(prod)
      # For products that have actual next reorder date of infinity
      begin
        prod.update_reorder_date
      rescue FloatDomainError
        prod.save!
      end
    end
  end

  private

    def find_params
      parsed_csv.map do |row|
        [ row.to_h['gusti_id'], row.to_h.except('gusti_id')]
      end.to_h
    end
end
