class PurchaseImportsController < ApplicationController
  before_action :logged_in_user
  before_action :check_file, only: :create

  def new
    @purchase_import = PurchaseImport.new
  end

  def create
    @purchase_import = PurchaseImport.new(import_params)
    if @purchase_import.save
      redirect_to root_url, notice: "Imported Items Sold to Customers Report successfully."
    else
      render :new
    end
  end

 
  private

    def check_file
      if params[:purchase_import].nil?
        redirect_to new_purchase_import_path, alert: "File missing for upload."
      elsif file_extname != ".xlsx"
        redirect_to new_purchase_import_path,\
          alert: "Incorrect file type. Please upload a .xlsx file"
      end
    end

    def import_params
      params.require(:purchase_import).permit(:file)
    end

    def file_extname
      File.extname(import_params[:file].original_filename)
    end
end
