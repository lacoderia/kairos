Rails.application.routes.draw do
  
  resources :items
  resources :orders
  resources :payments
  resources :emails
  resources :roles
  resources :invitations do
    collection do
      get 'by_user'
    end
  end
  
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self) rescue ActiveAdmin::DatabaseHitDuringLoad

  mount_devise_token_auth_for 'User', at: 'auth', :controllers => {:registrations => "registrations", :sessions => "sessions", :passwords => "passwords", :confirmations => "confirmations"}, defaults: { format: :json }

  devise_scope :user do
    match 'users/sign_up', :to => "registrations#create", :via => [:post, :options]
    match 'users/sign_in', :to => "sessions#create", :via => [:post, :options]
    match 'users/password', :to => "passwords#create", :via => [:post, :options]

    get 'users/confirm', :to => "users#confirm"
    get 'logout', :to => "sessions#destroy"
    get 'session', :to => "sessions#get"
  end 
  
  resources :users do
    collection do
      get 'by_external_id'
    end
  end
  
  resources :shipping_addresses do
    collection do
      get 'get_all_for_user'
    end
  end
  
  root to: "admin/dashboard#index"
end
