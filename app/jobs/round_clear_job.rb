class RoundClearJob < ApplicationJob
  def perform(game_id, round_num)
    Rails.logger.info "🎮 [RoundClearJob] Starting job for game #{game_id}"

    game  = Game.find(game_id)

    return if game.current_round != round_num

    round = Round.find_by(game_id: game.id, round_num: game.current_round)
    users = game.users
        
    5.times do |i|
      next if round["mem_#{i}_name"] != ''

       game_user = users.select {|u| u.game_user_number == i}.first
       
       if game_user.present?
        game_user.destroy
        game.update(participants: game.participants - 1)
       end
    end

    round.broadcast_round_update
  end
end
