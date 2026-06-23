Rails.application.routes.draw do
  root "dashboard#index"

  get "/login", to: "sessions#new"
  post "/login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy"

  resource :dashboard, only: :show, controller: :dashboard
  resource :ai_chat, only: :show, controller: :ai_chats
  get "/home_mocks", to: "home_mocks#index"

  resources :work_days, only: %i[index update] do
    collection do
      get :today
      patch :confirm_check_in
      patch :confirm_check_out
    end
  end

  resources :lunch_logs
  resources :diary_entries
  resources :hobby_items
  resources :paid_rides
  resources :ai_messages, only: %i[create show]
  resources :push_subscriptions, only: %i[create destroy]
  post "/webhooks/hermes_replies/:id", to: "hermes_replies#create", as: :hermes_reply_webhook
  post "/webhooks/hermes_actions/:id", to: "hermes_actions#create", as: :hermes_action_webhook

  get "/offline", to: "pwa#offline"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* without login redirects.
  get "service-worker" => "pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "pwa#manifest", as: :pwa_manifest
end
