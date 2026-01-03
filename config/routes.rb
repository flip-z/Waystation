Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  mount ActionCable.server => "/cable"

  root "posts#index"

  resource :session, only: %i[ new create destroy ]
  get "magic_link/:token", to: "magic_links#show", as: :magic_link
  resources :signups, only: %i[ new create ]

  resources :posts, only: %i[ index show ]
  resources :users, only: :show
  get "chat", to: "chat_messages#index"
  post "chat", to: "chat_messages#create", as: :chat_messages
  resources :chat_messages, only: [] do
    resources :chat_reactions, only: %i[ create ]
    delete "reactions", to: "chat_reactions#destroy", as: :chat_reaction
  end
  resources :campfires, only: :show do
    patch :close, on: :member
    resources :campfire_messages, only: :create
  end
  resource :profile, only: %i[ edit update ]
  get "files", to: "shell#files"

  namespace :admin do
    resources :invites, only: %i[ index new create ]
    resources :posts
  end
end
