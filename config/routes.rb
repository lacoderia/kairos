Rails.application.routes.draw do
  
  resources :orders do
    collection do
      get 'all'
      post 'create_with_items'
      post 'calculate_shipping_price'
    end
  end
  resources :payments
  resources :emails
  resources :roles
  
  resources :items do
    collection do
      get 'by_company'
    end
  end

  resources :summaries do
    collection do
      post 'send_by_email'
      get 'for_user'
      get 'by_period_with_downlines'
      get 'by_period_and_user_with_downlines_1_level'
    end
  end

  resources :invitations do
    collection do
      get 'by_user'
    end
  end

  resources :cards do
    collection do
      post 'create'
      post 'delete'
      post 'set_primary'
      get 'all'
      get 'get_device_session_id'
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
    member do
      post 'deactivate'
    end
    collection do
      get 'get_all_for_user'
    end
  end
  
  root to: "admin/dashboard#index"
end
