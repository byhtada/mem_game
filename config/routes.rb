Rails.application.routes.draw do
  post  :save_user_data,   controller: 'users'
  post  :get_user_data,   controller: 'users'
  post  :update_energy,   controller: 'users'

  
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
  post  :get_vote_update,   controller: 'rounds'
  post  :vote_for_mem,   controller: 'rounds'



  post :test_ready_for_game, controller: 'test'
  post :test_send_round_mems, controller: 'test'
  post :test_round_vote, controller: 'test'
  post :test_create_private_game,   controller: 'test'
end
