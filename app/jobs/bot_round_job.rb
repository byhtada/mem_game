class BotRoundJob < ApplicationJob
  def perform(round_id, game_user_id)
    round = Round.find(round_id)
    game_user = GameUser.find(game_user_id)

    Rails.logger.info "🤖 [BotRoundJob] #{Time.now.to_f} Starting job for round #{round_id} and game_user #{game_user_id}"
    
    mem_name = JSON.parse(game_user.mem_names).select { |mem| mem['active'] == true }.first['name']
    round.send_mem(game_user.user_id, mem_name)
  end
end