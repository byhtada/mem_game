# frozen_string_literal: true

class RoundsController < ApplicationController
  def get_round_update
    game  = Game.find(params[:game_id])
    round = Round.find_by(game_id: game.id, round_num: game.current_round)
    users = GameUsersService.new(game, @user).call

    my_mems = JSON.parse(GameUser.find_by(user_id: @user.id, game_id: params[:game_id]).mem_names)
    
    mems = get_round_mems(game, round)
    puts "mems #{mems}"
    round_progress_wait = round.round_progress_wait
    
  

    if round_progress_wait.negative? && round.state == 'play'
      5.times do |i|
        next if round["mem_#{i}_name"] != ''

         game_user = users.select {|u| u.game_user_number == i}.first
         
         if game_user.present?
          game_user.destroy
          game.update(participants: game.participants - 1)
         end
      end
    end

    users = GameUsersService.new(game.reload, @user).call

    ready_to_open = mems.length == game.participants
    
    if ready_to_open
      round.update(state: 'vote')
    end

    render json: {
      ready_to_open:,
      my_mems:,
      mems:,
      question: round.question_text,
      round:,
      users:,
      round_progress_wait:
    }
  end

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
      
      round.game.game_users.where(bot: true).each do |user|
        min = ::Round::VOTE_DURATION * 0.1
        max = ::Round::VOTE_DURATION * 0.5
        delay = rand(min..max)
        BotVoteJob.set(wait: delay.seconds).perform_later(round.id)
      end
    end

    render json: {}
  end

  def get_vote_update
    game  = Game.find(params[:game_id])
    round = Round.find_by(game_id: game.id, round_num: game.current_round)
    users = GameUsersService.new(game, @user).call
    
    vote_progress_wait = round.vote_progress_wait

    mems, total_votes = get_round_votes(round, users)

    puts "total_votes #{total_votes}"

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

    game.reload

    render json: {
      mems:,
      round:,
      users:,
      vote_finish: finish_round,
      vote_progress_wait:,
      finish_game:
    }
  end

  def vote_for_mem
    round = Round.find(params[:round_id])
    game = Game.find(round.game_id)
    current_votes = round[:"mem_#{params[:user_num]}_votes"]
    round.update("mem_#{params[:user_num]}_votes": current_votes + 1)

    render json: { }
  end

  private

  def create_round(game)
    finish_game = game.current_round >= Game::ROUNDS

    CalculateRoundResultService.new(game).call

    game.create_round if finish_game === false
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

  def get_round_mems(game, round)
    users = GameUsersService.new(game, @user).call

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

    mems = mems.sort { |f, s| f[:time] <=> s[:time] }
  end
end
