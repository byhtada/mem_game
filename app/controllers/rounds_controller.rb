# frozen_string_literal: true

class RoundsController < ApplicationController
  def send_round_mem
    game  = Game.find(params[:game_id])
    round = Round.find_by(game_id: game.id, round_num: game.current_round)

    round.send_mem(@user.id, params[:mem_name])

    render json: {}
  end

  def start_voting
    round = Round.find(params[:round_id])
    if round.start_voting == 0
      round.update(start_voting: Time.now.to_i, state: 'vote')
      FinishVotingJob.set(wait: ::Round::VOTE_DURATION).perform_later(round.id)
      
      round.game.game_users.where(bot: true).each do |user|
        min = ::Round::VOTE_DURATION * 0.1
        max = ::Round::VOTE_DURATION * 0.5
        delay = rand(min..max)
        BotVoteJob.set(wait: delay.seconds).perform_later(round.id)
      end
    end

    render json: {}
  end

  def vote_for_mem
    round = Round.find(params[:round_id])
    game = Game.find(round.game_id)
    current_votes = round[:"mem_#{params[:user_num]}_votes"]
    round.update("mem_#{params[:user_num]}_votes": current_votes + 1)

    round.broadcast_vote_update

    render json: { }
  end
end
