class ProductImportsController < ApplicationController
  def new
    @product_import = ProductImport.new
    @products = Product.all
  end

  def create
    @product_import = ProductImport.new(import_params)
    if @product_import.save
      redirect_to root_url, notice: "Imported products successfully."
    else
      render :new
    end
  end

  private
    
  def import_params
    params.require(:product_import).permit(:file)
  end

end
