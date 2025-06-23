class BotRestartJob < ApplicationJob
  queue_as :default

  def perform(game_id, game_user_id)
    game = Game.find(game_id)
    game_user = GameUser.find(game_user_id)
    
    rand(0..100) > 80 ? game_user.update(ready_to_restart: true) : nil
  end
end