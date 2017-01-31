class ProductsController < ApplicationController
  include ProductsHelper
  before_action :set_product, only: [:show, :edit, :update, :destroy]
  before_action :logged_in_user 

  def index
    @products = Product.all
  end

  def show
    @top_twenty = {}
    purchases_with_product = Purchase.all.select do |purchase| 
      purchase.item_id == @product.gusti_id
    end
    purchases_with_product.max_by(20) { |p| p.quantity }.each do |c|
      @top_twenty[c.customer] = c.quantity 
    end
    @total = @top_twenty.values.reduce(&:+) 
    #@top_five
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

  def import
    Product.import(params[:file])
    redirect_to root_url, notice: "Products imported."
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
