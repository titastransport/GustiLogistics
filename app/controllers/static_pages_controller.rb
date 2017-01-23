class StaticPagesController < ApplicationController

  def home
    if logged_in?
      redirect_to products_path
    else
      render 'home'
    end
  end
end
