class ProductsController < ApplicationController
  helper ProductsHelper
  before_action :set_product, only: [:show, :edit, :update, :destroy]
  before_action :logged_in_user

  def index
    @products = Product.select_setup_products.paginate(page: params[:page])
  end

  def show
    @first_half_top_customers = first_half_top_customers
    @second_half_top_customers = second_half_top_customers
  end

  def create
  end

  def update
    respond_to do |format|
      @product.update_attributes(product_params)
      @product.update_reorder_date 

      format.js
      format.html { redirect_to @product, notice: 'Product was successfully updated.' }
    end
  end

  def destroy
  end

  private

    def set_product
      @product = Product.find(params[:id])
    end

    def product_params
      params.require(:product).permit(:description, :current, :cover_time, :growth_factor, :enroute)
    end
end
