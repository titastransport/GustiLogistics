Rails.application.routes.draw do
  root 'static_pages#home'

  resources :product_imports
  resources :products do 
    collection { post :import }
  end

end
