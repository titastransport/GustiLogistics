class ActivityImportsController < ApplicationController
  include Importable
  before_action :logged_in_user
  before_action :check_valid_file_present, only: :create

  def new
    @activity_import = ActivityImport.new
  end

  def create
    @activity_import = ActivityImport.new(file: import_params[:file])

    if @activity_import.save
      redirect_to root_url, notice: "Imported Unit Activity Report successfully."
    else
      render :new
    end
  end

  private

    def import_params
      params.require(:activity_import).permit(:file)
    end
end
