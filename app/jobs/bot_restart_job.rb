class BotRestartJob < ApplicationJob
  def perform(game_id, game_user_id)
    game = Game.find(game_id)
    game_user = GameUser.find(game_user_id)
    
    if rand(0..100) > 0
      game_user.update(ready_to_restart: true)
      # Отправляем обновление через WebSocket после готовности бота к рестарту
      game.broadcast_restart_update if game.state == 'finishing'
    end
  end
end