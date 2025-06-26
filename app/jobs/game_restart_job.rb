class GameRestartJob < ApplicationJob
  def perform(game_id)
    game = Game.find(game_id)
    
    game.broadcast_restart_update
  end
end
