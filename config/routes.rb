Rails.application.routes.draw do
  post  :save_user_data,   controller: 'users'
  post  :get_user_data,   controller: 'users'

  post  :start_game,  controller: 'games'
  post  :join_to_game,   controller: 'games'
  post  :get_update_game_ready,   controller: 'games'
  post  :ready_for_game,   controller: 'games'
  post  :get_game_winner,   controller: 'games'
  post  :create_test_game,   controller: 'games'

  post  :get_round_update,   controller: 'rounds'
  post  :send_round_mem,   controller: 'rounds'
  post  :start_voting,   controller: 'rounds'
  post  :get_vote_update,   controller: 'rounds'
  post  :vote_for_mem,   controller: 'rounds'
end
