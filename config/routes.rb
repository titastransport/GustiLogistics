Rails.application.routes.draw do
  resources :products
  root      'products#index'

  get       '/update', to: 'purchases#new' 
end
