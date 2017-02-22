class ProductsController < ApplicationController
  before_action :set_product, only: [:show, :edit, :update, :destroy]
  before_action :logged_in_user

  def index
    @products = Product.select { |p| p.producer == "Faella" }
    @reorders = {} 
    @products.each do |product|
      @product = product
      @reorders[@product] = @product.reorder_in
    end
  end

  def show
    @first_half_top_customers = @product.first_half_top_customers
    @second_half_top_customers = @product.second_half_top_customers
  end

  def new
    @product = Product.new
  end

  def edit
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
    byebug
    if @product.update(product_params)
      # Assuming Current, Growth_Factor, or Cover has been changed
      @product.update_reorder_in
      @product.update_next_reorder_date
      redirect_to @product, notice: 'Product was successfully updated.'
    else
      render :edit
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
                                      :cover_time, :growth_factor, :ordered)
    end
end
