Rails.application.routes.draw do
  
  resources :emails
  resources :roles
  resources :invitations
  
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self) rescue ActiveAdmin::DatabaseHitDuringLoad

  mount_devise_token_auth_for 'User', at: 'auth', :controllers => {:registrations => "registrations", :sessions => "sessions", :passwords => "passwords"}, defaults: { format: :json }#, :skip => [:registrations]

  devise_scope :user do
    match 'users/sign_up', :to => "registrations#create", :via => [:post, :options]
    match 'users/sign_in', :to => "sessions#create", :via => [:post, :options]
    match 'users/password', :to => "passwords#create", :via => [:post, :options]

    get 'logout', :to => "sessions#destroy"
    get 'session', :to => "sessions#get"
  end 
  
  resources :users
  
  root to: "admin/dashboard#index"
end
