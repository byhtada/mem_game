class RoundChannel < ApplicationCable::Channel
  def subscribed
    Rails.logger.info "🔌 [RoundChannel#subscribed] User #{current_user&.id} attempting to subscribe with params: #{params.inspect}"
    
    begin
      # Проверяем права доступа пользователя к игре
      game_id = params[:game_id]
      Rails.logger.info "🔌 [RoundChannel#subscribed] Looking for game_id: #{game_id}"
      
      game = Game.find(game_id)
      Rails.logger.info "🔌 [RoundChannel#subscribed] Found game: #{game.id} (state: #{game.state})"
      
      game_user = GameUser.find_by(game_id: game.id, user_id: current_user.id)
      Rails.logger.info "🔌 [RoundChannel#subscribed] GameUser lookup - Game: #{game.id}, User: #{current_user.id}, GameUser: #{game_user&.id}"
      
      if game_user.present?
        stream_for game
        Rails.logger.info "🎮 [RoundChannel#subscribed] ✅ User #{current_user.id} subscribed to round updates for game #{game.id}"
        
        # Сразу отправляем текущее состояние раунда при подписке
        send_round_update(game)
      else
        Rails.logger.warn "🎮 [RoundChannel#subscribed] ❌ User #{current_user&.id} rejected for game #{game&.id} - GameUser not found"
        reject
      end
    rescue => e
      Rails.logger.error "🔌 [RoundChannel#subscribed] ❌ Error during subscription: #{e.class} - #{e.message}"
      Rails.logger.error "🔌 [RoundChannel#subscribed] Backtrace: #{e.backtrace&.first(5)&.join(', ')}"
      reject
    end
  end

  def unsubscribed
    Rails.logger.info "🔌 [RoundChannel#unsubscribed] User #{current_user&.id} unsubscribed from round channel"
  end

  private

  def send_round_update(game)
    Rails.logger.info "📤 [RoundChannel#send_round_update] Sending round update to user #{current_user.id} for game #{game.id}"
    
    round = Round.find_by(game_id: game.id, round_num: game.current_round)
    
    # Проверяем, что раунд существует и игра в состоянии 'playing'
    if round.nil? || game.state != 'playing'
      Rails.logger.warn "📤 [RoundChannel#send_round_update] No active round found or game not in playing state - game: #{game.id}, state: #{game.state}, round: #{round&.id}"
      reject
      return
    end
    
    users = GameUsersService.new(game, current_user).call
    game_user = GameUser.find_by(user_id: current_user.id, game_id: game.id)
    
    if game_user.nil?
      Rails.logger.error "📤 [RoundChannel#send_round_update] GameUser not found - rejecting"
      reject
      return
    end
    
    my_mems = JSON.parse(game_user.mem_names)
    
    # Получаем мемы раунда
    mems = get_round_mems(game, round, users)
    round_progress_wait = round.round_progress_wait
    
    # Обрабатываем отключение игроков при истечении времени
    if round_progress_wait.negative? && round.state == 'play'
      5.times do |i|
        next if round["mem_#{i}_name"] != ''

        game_user = users.select {|u| u.game_user_number == i}.first
        
        if game_user.present?
          game_user.destroy
          game.update(participants: game.participants - 1)
        end
      end
      users = GameUsersService.new(game.reload, current_user).call
    end

    ready_to_open = mems.length == game.participants
    
    if ready_to_open
      round.update(state: 'vote')
    end
    
    data = {
      ready_to_open: ready_to_open,
      my_mems: my_mems,
      mems: mems,
      question: round.question_text,
      round: round,
      users: users,
      round_progress_wait: round_progress_wait
    }
    
    Rails.logger.info "📤 [RoundChannel#send_round_update] Data: #{data.inspect}"
    transmit(data)
    Rails.logger.info "📤 [RoundChannel#send_round_update] Transmit completed"
  end

  def get_round_mems(game, round, users)
    mems = []
    5.times do |i|
      next if round[:"mem_#{i}_name"] == ''

      user = users.select { |mem_game_user| mem_game_user.game_user_number == i }.first
      mems.append({ mem: round[:"mem_#{i}_name"],
                    time: round[:"mem_#{i}_time"],
                    user_num: i,
                    user_id: user.user_id,
                    name: user.user_name,
                    avatar: user.user_ava })
    end

    mems.sort { |f, s| f[:time] <=> s[:time] }
  end
end 