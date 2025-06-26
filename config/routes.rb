Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Action Cable WebSocket endpoint
  mount ActionCable.server => '/cable'

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Health check для продакшена
  get "health", to: "application#health"

  # Defines the root path route ("/")
  # root "posts#index"

  # Пользователи
  get '/users/me', to: 'users#show'
  patch '/users/me', to: 'users#update'

  # Игры
  post '/games', to: 'games#create'
  post '/games/join', to: 'games#join'
  post '/games/leave', to: 'games#leave'
  get '/games/search', to: 'games#search'
  get '/games/:id', to: 'games#show'
  post '/games/:id/restart', to: 'games#restart'
  get '/games', to: 'games#index'

  # Раунды
  post '/rounds', to: 'rounds#create'
  post '/rounds/:id/vote', to: 'rounds#vote'
  get '/rounds/:id', to: 'rounds#show'

  # Турниры
  post '/tournaments/:id/register', to: 'tournaments#register'
  get '/tournaments', to: 'tournaments#index'

  # Друзья
  get '/friends', to: 'users#friends'
  post '/friends/add', to: 'users#add_friend'

  # Тестовые эндпоинты
  post '/test/create_user', to: 'test#create_user'
  post '/test/create_game', to: 'test#create_game'
  post '/test/create_round', to: 'test#create_round'
  post '/test/join_game', to: 'test#join_game'
  post '/test/vote', to: 'test#vote'
  post '/test/start_next_round', to: 'test#start_next_round'

  # Админ панель (если нужна)
  # namespace :admin do
  #   resources :users
  #   resources :games
  #   resources :tournaments
  # end

  # Health check endpoint
  get :health, controller: 'application'
  
  # Корневой маршрут для фронтенда
  root 'application#index'
  
  # API маршруты
  post :get_payment_link, controller: 'application'
  post :telegram_callback, controller: 'application'
  post :set_webhook, controller: 'application'
  post :create_tg_message, controller: 'application'
  post :test_telegram, controller: 'application'

  

  post  :save_user_data,   controller: 'users'
  post  :get_user_data,   controller: 'users'
  post  :update_energy,   controller: 'users'
  post  :register_in_tournament,   controller: 'users'
  post :get_user_friends, controller: 'users'
  post :convert_energy, controller: 'users'


  post  :find_game,  controller: 'games'
  post  :create_game,  controller: 'games'
  post  :join_to_game,   controller: 'games'

  post  :get_update_game_ready,   controller: 'games'
  post  :get_game_winner,   controller: 'games'
  post  :get_restart_update,   controller: 'games'
  post  :ready_to_restart,   controller: 'games'

  post  :get_round_update,   controller: 'rounds'
  post  :send_round_mem,   controller: 'rounds'
  post  :start_voting,   controller: 'rounds'
  post  :vote_for_mem,   controller: 'rounds'



  post :test_ready_for_game, controller: 'test'
  post :test_send_round_mems, controller: 'test'
  post :test_round_vote, controller: 'test'
  post :test_create_private_game,   controller: 'test'
  post :update_mems, controller: 'test'
  post :test_round_change_question, controller: 'test'

  post :test_update_names, controller: 'test'
  
  # Fallback для SPA - все неопределенные маршруты направляем на фронтенд
  get '*path', to: 'application#index', constraints: ->(request) do
    !request.xhr? && request.format.html?
  end
end
