class ReordersController < ApplicationController
  def index
    @reorders = Reorder.all
    @reorders_by_date = @reorders.group_by(&:date)
    @date = params[:date] ? Date.parse(params[:date]) : Date.today
  end
end
