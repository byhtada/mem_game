class VoteChannel < ApplicationCable::Channel
  def subscribed
    Rails.logger.info "🔌 [VoteChannel#subscribed] User #{current_user&.id} attempting to subscribe with params: #{params.inspect}"
    
    begin
      # Проверяем права доступа пользователя к игре
      game_id = params[:game_id]
      Rails.logger.info "🔌 [VoteChannel#subscribed] Looking for game_id: #{game_id}"
      
      game = Game.find(game_id)
      Rails.logger.info "🔌 [VoteChannel#subscribed] Found game: #{game.id} (state: #{game.state})"
      
      game_user = GameUser.find_by(game_id: game.id, user_id: current_user.id)
      Rails.logger.info "🔌 [VoteChannel#subscribed] GameUser lookup - Game: #{game.id}, User: #{current_user.id}, GameUser: #{game_user&.id}"
      
      if game_user.present?
        stream_for game
        Rails.logger.info "🎮 [VoteChannel#subscribed] ✅ User #{current_user.id} subscribed to vote updates for game #{game.id}"
        
        # Сразу отправляем текущее состояние голосования при подписке
        send_vote_update(game)
      else
        Rails.logger.warn "🎮 [VoteChannel#subscribed] ❌ User #{current_user&.id} rejected for game #{game&.id} - GameUser not found"
        reject
      end
    rescue => e
      Rails.logger.error "🔌 [VoteChannel#subscribed] ❌ Error during subscription: #{e.class} - #{e.message}"
      Rails.logger.error "🔌 [VoteChannel#subscribed] Backtrace: #{e.backtrace&.first(5)&.join(', ')}"
      reject
    end
  end

  def unsubscribed
    Rails.logger.info "🔌 [VoteChannel#unsubscribed] User #{current_user&.id} unsubscribed from vote channel"
  end

  private

  def send_vote_update(game)
    Rails.logger.info "📤 [VoteChannel#send_vote_update] Sending vote update to user #{current_user.id} for game #{game.id}"
    
    round = Round.find_by(game_id: game.id, round_num: game.current_round)
    
    # Проверяем, что раунд существует и игра в состоянии 'playing', а раунд в состоянии 'vote'
    #if round.nil? || game.state != 'playing' || round.state != 'vote'
    #  Rails.logger.warn "📤 [VoteChannel#send_vote_update] No active voting round found - game: #{game.id}, game_state: #{game.state}, round_state: #{round&.state}"
    #  reject
    #  return
    #end
    
    users = GameUsersService.new(game, current_user).call
    game_user = GameUser.find_by(user_id: current_user.id, game_id: game.id)
    
    if game_user.nil?
      Rails.logger.error "📤 [VoteChannel#send_vote_update] GameUser not found - rejecting"
      reject
      return
    end
    
    # Получаем данные голосования
    vote_progress_wait = round.vote_progress_wait
    mems, total_votes = get_round_votes(round, users)
    
    # Проверяем завершение голосования
    finish_game = false
    finish_round = total_votes >= game.participants || vote_progress_wait.negative?
    
    if finish_round && round.state == 'vote'
      round.update(state: 'close')

      if round.round_num >= Game::ROUNDS
        finish_game = true
        CalculateRoundResultService.new(game).call
        game.finish_game
      else
        create_round(game) 
        round = Round.find_by(game_id: game.id, round_num: game.current_round)
      end
    end
    
    data = {
      mems: mems,
      round: round,
      users: users,
      vote_finish: finish_round,
      vote_progress_wait: vote_progress_wait,
      finish_game: finish_game
    }
    
    Rails.logger.info "📤 [VoteChannel#send_vote_update] Data: #{data.inspect}"
    transmit(data)
    Rails.logger.info "📤 [VoteChannel#send_vote_update] Transmit completed"
  end

  def get_round_votes(round, users)
    total_votes = 0

    mems = []
    5.times do |i|
      total_votes += round["mem_#{i}_votes"]

      next unless round["mem_#{i}_name"] != ''

      user = users.select { |mem_game_user| mem_game_user.game_user_number == i }.first
      mems.append({ mem: round["mem_#{i}_name"],
                    time: round["mem_#{i}_time"],
                    votes: round["mem_#{i}_votes"],
                    user_num: i,
                    user_id: user.user_id,
                    name: user.user_name,
                    avatar: user.user_ava })
    end

    mems = mems.sort { |f, s| f[:time] <=> s[:time] }

    [mems, total_votes]
  end

  def create_round(game)
    finish_game = game.current_round >= Game::ROUNDS

    CalculateRoundResultService.new(game).call

    game.create_round if finish_game === false
  end
end 