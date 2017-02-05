class ProductsController < ApplicationController
  include ProductsHelper
  before_action :set_product, only: [:show, :edit, :update, :destroy]
  before_action :logged_in_user 

  def index
    @products = Product.all.select { |p| p.producer == "Faella" }
  end

  def get_month_name(num)
    Date::MONTHNAMES[num]
  end

  def last_n_months(most_recent_month, n) 
    months = []
    most_recent_month.downto(most_recent_month - (n - 1)) do |m|
      m += 12 if m <= 0
      months << m
    end
    months
  end

  def show
    @top_twenty = Hash.new(0)
    most_recent_month = CustomerPurchaseOrder.first.date.month     
    # using 6 months for now, because seems like best guess for predicting, if I
    # had to choose only one
    months_to_query = last_n_months(most_recent_month, 6)
    CustomerPurchaseOrder.all.select do |purchase| 
      months_to_query.include? purchase.date.month 
   # purchases_with_product = CustomerPurchaseOrder.all.select do |purchase| 
   #   purchase.product.gusti_id == @product.gusti_id
   # end
   # purchases_with_product.max_by(20) { |p| p.quantity }.each do |c|
   #   @top_twenty[c.customer.name] += c.quantity 
   # end
   # @total = @top_twenty.values.reduce(&:+) 
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
