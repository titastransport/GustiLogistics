class CalendarsController < ApplicationController
  def index
    @products = Product.select { |product| !product.next_reorder_date.nil? }
    @products_by_reorder_date = @products.group_by(&:next_reorder_date)
    @date = params[:date] ? Date.parse(params[:date]) : Date.today
  end
end
