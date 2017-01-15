Rails.application.routes.draw do
  resources :product_imports
  resources :products do 
    collection { post :import }
  end

  root      'products#index'

end
