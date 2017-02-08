class ActivityImportsController < ApplicationController
  before_action :logged_in_user
  before_action :valid_file?, only: :create

  def new
    @activity_import = ActivityImport.new
    @products = Product.all
  end

  def create
    @activity_import = ActivityImport.new(import_params)
    if @activity_import.save
      redirect_to root_url, notice: "Imported Unit Activity Report successfully."
    else
      @products = Product.all
      render :new
    end
  end

  def valid_file?
    file = import_params[:file]
    extname = File.extname(file.original_filename)
    unless extname == ".xlsx"
      flash[:error] = "File not present."
      redirect_to new_activity_import_path
    end
  end

  private

  def import_params
    params.require(:activity_import).permit(:file)
  end

end
