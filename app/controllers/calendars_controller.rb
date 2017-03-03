class CalendarsController < ApplicationController
  def index
    @products = Product.select { |product| !product.next_reorder_date.nil? }

    @products.each do |product| 
      unless product.enroute
        product.update_reorder_status && product.save 
      end
    end

    @products_by_reorder_date = @products.group_by(&:next_reorder_date)
    # Defaults to today's date to use this month
    # Date parameter changed by clicking arrow in view
    @date = params[:date] ? Date.parse(params[:date]) : Date.today
  end
end
