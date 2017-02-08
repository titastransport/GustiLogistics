class PurchaseImportsController < ApplicationController
  before_action :logged_in_user
  before_action :check_file, only: :create

  def new
    @purchase_import = PurchaseImport.new
  end

  def create
    @purchase_import = PurchaseImport.new(import_params)
    if @purchase_import.save
      redirect_to root_url, notice: "Imported Unit purchase Report successfully."
    else
      render :new
    end
  end

  def check_file
    if params[:purchase_import].nil?
      redirect_to new_purchase_import_path, alert: "File missing for upload."
      return
    end

    filename = import_params[:file].original_filename
    extname = File.extname(filename)
    unless extname == ".xlsx"
      redirect_to new_purchase_import_path,\
        alert: "Incorrect file type. Please upload a .xlsx file"
    end
  end

  private

  def import_params
    params.require(:purchase_import).permit(:file)
  end

end
