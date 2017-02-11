class ProductsController < ApplicationController
  include ProductsHelper
  before_action :set_product, only: [:show, :edit, :update, :destroy]
  before_action :logged_in_user

  def index
    @products = Product.select { |p| p.producer == "Faella" }
    @reorders = Hash.new
    @products.each do |product|
      @product = product
      @reorders[@product] = naive_reorder_in
    end
  end

  def show
    tops = find_top_customers(20)
    @top_twenty_first_half = tops[:first_half]
    @top_twenty_second_half = tops[:second_half]

    retails = total_retail_units_sold
    @top_twenty_first_half[:Retail] = retails[:first_half]
    @top_twenty_second_half[:Retail] = retails[:second_half]

    # sort
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
    if @product.update(product_params)
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
      params.require(:product).permit(:gusti_id, :description, :current, :reorder_in)
    end
end
