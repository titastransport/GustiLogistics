Rails.application.routes.draw do
  root   'static_pages#home'
  get    '/login',      to: 'sessions#new'
  post   '/login',      to: 'sessions#create'
  delete '/logout',     to: 'sessions#destroy'
  get    '/calendar',   to: 'reorders#index'

  resources :product_imports
  resources :products do 
    collection { post :import }
  end

end
