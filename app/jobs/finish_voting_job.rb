class FinishVotingJob < ApplicationJob
  def perform(round_id)
    round = Round.find(round_id)

    vote_update = round.build_vote_update_data
    vote_update[:vote_finish] = true

    VoteChannel.broadcast_to(round.game, vote_update)

    round.finish_voting
  end
end
