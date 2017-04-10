class ProductImport
  include Dateable
  attr_reader :parsed_csv, :products_params

  def initialize(file)
    @parsed_csv = CSVParser.new(file).parsed
    @products_params = find_params
  end

  def save
    products = import_products

    if products.all?(&:valid?)
      products.each(&:save)
    else
      display_errors(products)
    end
  end

  private

    def find_params
      parsed_csv.map { |row| row.to_h }
    end

    def date_object_for_period(date_str)
      return nil if date_str == 'nil'

      month = date_str.match(/[a-z]+/i).to_s 
      day = date_str.match(/\d+/).to_s.to_i
      Date.new(Date.today.year, month_number_from(month), day)
    end

    def product_params_from(current_params)
      {
        gusti_id: current_params['gusti_id'],
        description: current_params['description'],
        lead_time: current_params['lead_time'],
        travel_time: current_params['travel_time'],
        cover_time: current_params['cover_time'],
        growth_factor: current_params['growth_factor'],
        cant_travel_start: date_object_for_period(current_params['cant_travel_start']),
        cant_travel_end: date_object_for_period(current_params['cant_travel_end']),
        cant_produce_start: date_object_for_period(current_params['cant_produce_start']),
        cant_produce_end: date_object_for_period(current_params['cant_produce_end'])
      }
    end

    def import_products
      products_params.map do |current_params|
        if (existing_product = Product.find_by(gusti_id: current_params['gusti_id'].upcase))
          existing_product.update(product_params_from(current_params))
          existing_product
        else
          Product.new(product_params_from(current_params))
        end
      end
    end

    def display_errors(invalid_products)
      invalid_products.each_with_index do |prod, index|
        prod.errors.full_messages.each do |message|
          puts "Row: #{index}, error: #{message}"
        end
      end
    end
end
