class BotVoteJob < ApplicationJob
  queue_as :bot_vote_sequential

  def perform(round_id)
    Rails.logger.info "🎮 [BotVoteJob] #{Time.now.to_f} Starting job for round #{round_id}"

    round = Round.find(round_id)
    possible_votes = []
    5.times do |i|
      possible_votes.append(i) if round[:"mem_#{i}_name"] != ''
    end
    vote_for = possible_votes.sample
    
    current_votes = round[:"mem_#{vote_for}_votes"]
    round.update("mem_#{vote_for}_votes": current_votes + 1)

    round.broadcast_vote_update
  end
end