class RestartChannel < ApplicationCable::Channel
  def subscribed
    Rails.logger.info "🔌 [RestartChannel#subscribed] User #{current_user&.id} attempting to subscribe with params: #{params.inspect}"
    
    begin
      # Проверяем права доступа пользователя к игре
      game_id = params[:game_id]
      Rails.logger.info "🔌 [RestartChannel#subscribed] Looking for game_id: #{game_id}"
      
      game = Game.find(game_id)
      Rails.logger.info "🔌 [RestartChannel#subscribed] Found game: #{game.id} (state: #{game.state})"
      
      game_user = GameUser.find_by(game_id: game.id, user_id: current_user.id)
      Rails.logger.info "🔌 [RestartChannel#subscribed] GameUser lookup - Game: #{game.id}, User: #{current_user.id}, GameUser: #{game_user&.id}"
      
      if game_user.present?
        stream_for game
        Rails.logger.info "🔄 [RestartChannel#subscribed] ✅ User #{current_user.id} subscribed to restart for game #{game.id}"
        
        # Сразу отправляем текущее состояние рестарта при подписке
        send_restart_update(game)
      else
        Rails.logger.warn "🔄 [RestartChannel#subscribed] ❌ User #{current_user&.id} rejected for game #{game&.id} - GameUser not found"
        reject
      end
    rescue => e
      Rails.logger.error "🔌 [RestartChannel#subscribed] ❌ Error during restart subscription: #{e.class} - #{e.message}"
      Rails.logger.error "🔌 [RestartChannel#subscribed] Backtrace: #{e.backtrace&.first(5)&.join(', ')}"
      reject
    end
  end

  def unsubscribed
    Rails.logger.info "🔌 [RestartChannel#unsubscribed] User #{current_user&.id} unsubscribed from restart channel"
  end

  private

  def send_restart_update(game)
    Rails.logger.info "📤 [RestartChannel#send_restart_update] Sending restart update to user #{current_user.id} for game #{game.id}"
    
    # Отправляем обновление только текущему пользователю при подписке
    users = GameUsersService.new(game, current_user).call
    restart_progress_wait = game.restart_progress_wait
    new_game = nil

    # Логика рестарта (из контроллера)
    if restart_progress_wait.negative? || game.users.select {|u| u.ready_to_restart}.count == game.participants
      if game.state != 'close'
        new_game = Game.create(participants: 4)

        game.users.each do |user|
          next unless user.ready_to_restart

          new_game.join_to_game(User.find(user.user_id))
        end
        
        game.update(state: 'close')
        new_game.update(state: 'playing') if new_game.participants == new_game.users.count
      end
    end

    # Найти новую игру для пользователя
    new_game = Game.find(GameUser.where(user_id: current_user.id).last.game_id) if new_game.nil?

    data = {
      restart_progress_wait: restart_progress_wait,
      ready_to_start: game.reload.state == 'close',
      users: users,
      new_game: new_game&.as_json,
      game: game.as_json,
      user_id: current_user.id,
      winners_ids: game.winners.pluck(:game_user_number),
    }
    
    Rails.logger.info "📤 [RestartChannel#send_restart_update] Data: #{data.inspect}"
    transmit(data)
    Rails.logger.info "📤 [RestartChannel#send_restart_update] Transmit completed"
  end
end 