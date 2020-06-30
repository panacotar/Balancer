Rails.application.routes.draw do
  root to: 'pages#home'
  get 'about', to: 'pages#about'
  get :dashboard, to: "users#dashboard"
  devise_for :users
  
  resources :projects, only: %i[show new create edit update] do
    resources :campaigns, only: %i[new create]
  end

  resources :campaigns, only: %i[index]
  resources :shareholders, only: %i[create update]
  resources :transactions, only: %i[index create updated] 
end
