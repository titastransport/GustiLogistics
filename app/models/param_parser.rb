class ParamParser
  PATH_TO_PARAMS = 'db/product_parameters.csv'
  attr_reader :parsed_csv, :products_for_params

  def initialize
    @parsed_csv = CSVParser.new(PATH_TO_PARAMS).parsed
    @products_for_params = find_products_for_params
  end

  # products_for_params = { 'Item ids' => [all ids] }
  # products_for_parms['Item ids'] => All ids
  
  def find_products_for_params
    pairs = Hash.new { |hash, key| hash[key] = [] }

    parsed_csv.each do |row|
      row.to_h.each do |param, value|
        pairs[param.pluralize] << value  
      end
    end

    pairs
  end

  # params_to_set = [ 
  #                   description => products_for_params['Item ID']
  #                   lead_time, 
  #                   travel_time, 
  #                   cover_time, 
  #                   growth factor, 
  #                   cant_travel_start, 
  #                   cant_travel_end, 
  #                   cant_produce_start,
  #                   cant_produce_end 
  #                 ]

  def list_of_valid_products
    products_for_params['Item IDs']
  end

  def parse_times_for(param)
    products_for_params[param] 
  end
end
