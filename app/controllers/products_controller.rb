class ProductsController < ApplicationController
  helper ProductsHelper
  before_action :set_product, only: [:show, :edit, :update, :destroy]
  before_action :logged_in_user

  def index
    @products = Product.setup
    @products.each { |product| product.update_reorder_status && product.save! }
  end

  def show
    @first_half_top_customers  = first_half_top_customers
    @second_half_top_customers = second_half_top_customers
  end

  def create
    @product = Product.new(product_params)

    if @product.save
      redirect_to @product, notice: 'Product was successfully created.'
    else
      render :new
    end
  end

  def update
    respond_to do |format|
      if @product.update_attributes(product_params)
        unless @product.enroute
          @product.update_reorder_status
          @product.save!
        end

        format.js
        format.html { redirect_to @product, notice: 'Product was successfully updated.' }
      else
        render :edit
      end
    end
  end

  def destroy
    @product.destroy

    redirect_to products_url, notice: 'Product was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_product
      @product = Product.find(params[:id])
    end

    def product_params
      params.require(:product).permit(:description, :current,\
                                      :cover_time, :growth_factor, :enroute)
    end

    def setup_product(product)
      !(product.next_reorder_date.nil?)
    end
end
