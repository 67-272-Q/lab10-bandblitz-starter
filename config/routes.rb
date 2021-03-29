Rails.application.routes.draw do
  resources :genres
  resources :bands
  resources :band_genres
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
