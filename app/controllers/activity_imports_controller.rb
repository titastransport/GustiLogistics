class ActivityImportsController < ApplicationController
  before_action :logged_in_user
  before_action :check_file, only: :create

  def new
    @activity_import = ActivityImport.new
  end

  def create
    @activity_import = ActivityImport.new(import_params)
    if @activity_import.save
      redirect_to root_url, notice: "Imported Unit Activity Report successfully."
    else
      render :new
    end
  end

  def check_file
    if params[:activity_import].nil?
      redirect_to new_activity_import_path, alert: "File missing for upload."
      #return
    elsif file_extname != ".xlsx"
      redirect_to new_activity_import_path,\
        alert: "Incorrect file type. Please upload a .xlsx file"
    end
  end
  
  private

  def import_params
    params.require(:activity_import).permit(:file)
  end

  def filename
    import_params[:file].original_filename
  end
  
  def file_extname
    File.extname(filename)
  end
end
