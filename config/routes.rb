Rails.application.routes.draw do
  root to: 'pages#home'
  get :about, to: 'pages#about'
  get :dashboard, to: "users#dashboard"
  get :successfulpledge, to: 'pages#successfulpledge'
  devise_for :users
  
  resources :projects, only: %i[show new create edit update] do
    
    resources :campaigns, only: %i[new create]
    resources :shareholders, only: %i[new create]
  end

  resources :campaigns, only: %i[index]
  resources :transactions, only: %i[index create updated] 
end
