class GameChannel < ApplicationCable::Channel
  def subscribed
    Rails.logger.info "🔌 [GameChannel#subscribed] User #{current_user&.id} attempting to subscribe with params: #{params.inspect}"
    
    begin
      # Проверяем права доступа пользователя к игре
      game_id = params[:game_id]
      Rails.logger.info "🔌 [GameChannel#subscribed] Looking for game_id: #{game_id}"
      
      game = Game.find(game_id)
      Rails.logger.info "🔌 [GameChannel#subscribed] Found game: #{game.id} (state: #{game.state})"
      
      game_user = GameUser.find_by(game_id: game.id, user_id: current_user.id)
      Rails.logger.info "🔌 [GameChannel#subscribed] GameUser lookup - Game: #{game.id}, User: #{current_user.id}, GameUser: #{game_user&.id}"
      
      if game_user.present?
        stream_for game
        Rails.logger.info "🎮 [GameChannel#subscribed] ✅ User #{current_user.id} subscribed to game #{game.id}"
        
        # Сразу отправляем текущее состояние игры при подписке
        send_game_update(game)
      else
        Rails.logger.warn "🎮 [GameChannel#subscribed] ❌ User #{current_user&.id} rejected for game #{game&.id} - GameUser not found"
        reject
      end
    rescue => e
      Rails.logger.error "🔌 [GameChannel#subscribed] ❌ Error during subscription: #{e.class} - #{e.message}"
      Rails.logger.error "🔌 [GameChannel#subscribed] Backtrace: #{e.backtrace&.first(5)&.join(', ')}"
      reject
    end
  end

  def unsubscribed
    Rails.logger.info "🔌 [GameChannel#unsubscribed] User #{current_user&.id} unsubscribed from game channel"
  end

  private

  def send_game_update(game)
    Rails.logger.info "📤 [GameChannel#send_game_update] Sending update to user #{current_user.id} for game #{game.id}"
    
    # Отправляем обновление только текущему пользователю при подписке
    users = GameUsersService.new(game, current_user).call
    
    data = {
      ready_to_start: game.ready_to_start,
      ready_progress_wait: game.ready_progress_wait,
      users: users,
      game: game.as_json,
      my_mems: []
    }
    
    Rails.logger.info "📤 [GameChannel#send_game_update] Data: #{data.inspect}"
    transmit(data)
    Rails.logger.info "📤 [GameChannel#send_game_update] Transmit completed"
  end
end 