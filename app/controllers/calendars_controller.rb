class CalendarsController < ApplicationController
  def index
    @products = Product.select_setup_products 

    @products.each do |product| 
      unless product.enroute || product.next_reorder_date > Date.today
        product.update_reorder_date 
      end
    end

    @products_by_reorder_date = @products.group_by(&:next_reorder_date)
    # Defaults to today's date to use this month
    # Date parameter changed by clicking arrow in view
    @date = params[:date] ? Date.parse(params[:date]) : Date.today
  end
end
