Rails.application.routes.draw do
  root to: 'pages#home'
  post '/stripe/webhook', to: 'stripe_webhooks#create'
  get '/healthcheck', to: 'healthchecks#show'
  # Override the engine's public blob-creation endpoint.
  post '/rails/active_storage/direct_uploads', to: 'direct_uploads#create'
  get :about, to: 'pages#about'
  get :dashboard, to: "users#dashboard"
  get :successfulpledge, to: 'pages#successfulpledge'
  devise_for :users, controllers: { sessions: 'users/sessions', registrations: 'users/registrations',
                                    passwords: 'users/passwords' }

  resources :projects, only: %i[show new create edit update] do

    resources :campaigns, only: %i[new create edit update]
    resources :shareholders, only: %i[new create]
  end

  resources :campaigns, only: %i[index]
  resources :transactions, only: %i[index create update]
  resources :orders, only: [:show, :create] do
    resources :payments, only: :new
  end
end
