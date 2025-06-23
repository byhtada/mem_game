class BotVoteJob < ApplicationJob
  queue_as :default

  def perform(round_id)
    round = Round.find(round_id)
    possible_votes = []
    5.times do |i|
      possible_votes.append(i) if round[:"mem_#{i}_name"] != ''
    end
    vote_for = possible_votes.sample
    
    current_votes = round[:"mem_#{vote_for}_votes"]
    round.update("mem_#{vote_for}_votes": current_votes + 1)
  end
end