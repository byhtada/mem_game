# frozen_string_literal: true

class RoundsController < ApplicationController


  def get_round_update
    game  = Game.find(params[:game_id])
    round = Round.find_by(game_id: game.id, round_num: game.current_round)
    users = game.users

    my_mems = GameUser.find_by(user_id: @user.id, game_id: params[:game_id]).mem_names
    my_mems = JSON.parse(my_mems)

    
    mems = get_round_mems(game, round)
    round_progress_wait = 100 - (100 * (Time.now.to_i - round.created_at.to_i).to_f / 30).to_i

    ready_to_open = mems.length == game.participants
    if ready_to_open == false && round_progress_wait.negative?
      send_random_mem(game, round, users)
      mems = get_round_mems(game, round)
      ready_to_open = true
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

    user_in_game = GameUser.find_by(game_id: params[:game_id], user_id: @user.id)
    user_number = user_in_game.game_user_number

    new_user_mems = []
    JSON.parse(user_in_game.mem_names).each do |mem|
      new_mem = { name: mem['name'], active: mem['active'] }
      new_mem[:active] = false if params[:mem_name] == mem['name']
      new_user_mems.append(new_mem)
    end
    user_in_game.update(mem_names: JSON.dump(new_user_mems))

    round.update("mem_#{user_number}_name": params[:mem_name],
                 "mem_#{user_number}_time": Time.now.to_f)

    test_send_round_mems(game)

    render json: {}
  end


  def start_voting
    Round.find(params[:round_id]).update(start_voting: Time.now.to_i)
    render json: {}
  end

  def get_vote_update
    game  = Game.find(params[:game_id])
    round = Round.find_by(game_id: game.id, round_num: game.current_round)
    users = game.users

    total_votes = 0
    mems = []
    game.participants.times do |i|
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

    finish_round = total_votes >= game.participants || Time.now.to_i - round.created_at.to_i < 7
    finish_game = game.current_round >= 3 && total_votes >= game.participants
    vote_progress_wait = 100 - (100 * (Time.now.to_i - round.start_voting).to_f / 30).to_i

    if vote_progress_wait.negative? && finish_round == false

      (game.participants - total_votes).times do |_i|
        vote_for_user = rand(0..game.participants - 1)
        current_votes = round["mem_#{vote_for_user}_votes"]
        round.update("mem_#{vote_for_user}_votes": current_votes + 1)
      end

      calculate_round_result(game)
      if (game.current_round >= 3) == false
        game.create_round
        finish_game = false
      end

      finish_round = true
    end

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

    total_votes = 0
    game.participants.times do |i|
      total_votes += round["mem_#{i}_votes"]
    end

    finish_round = total_votes >= game.participants
    finish_game = game.current_round >= 3

    if finish_round
      calculate_round_result(game)

      game.create_round if finish_game === false
    end


    render json: { finish_round:,
                   finish_game:,
                   users: finish_round ? game.users : [] }
  end


  private 

  def get_round_mems(game, round)
    users = game.users

    mems = []
    game.participants.times do |i|
      next unless round[:"mem_#{i}_name"] != ''

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
 
  def send_random_mem(game, round, users)
    game.participants.times do |i|
      next unless round[:"mem_#{i}_name"] == ''

      user = users.select { |mem_game_user| mem_game_user.game_user_number == i }.first
      active_mem = JSON.parse(user.mem_names).select { |mem| mem['active'] == true }.first

      round.update("mem_#{i}_name": active_mem['name'])
      round.update("mem_#{i}_time": Time.now.to_f)


      new_user_mems = []
      JSON.parse(user.mem_names).each do |mem|
        new_mem = { name: mem['name'], active: mem['active'] }
        new_mem[:active] = false if active_mem['name'] == mem['name']
        new_user_mems.append(new_mem)
      end
      user.update(mem_names: JSON.dump(new_user_mems))
    end
  end

  def calculate_round_result(game)
    round = Round.find_by(game_id: game.id, round_num: game.current_round)
    users = game.users

    game.participants.times do |i|
      user = users.select { |mem_game_user| mem_game_user.game_user_number == i }.first
      round_points = round["mem_#{i}_votes"]
      user.update(game_points: user.game_points + round_points)
    end
  end

  def test_send_round_mems(game)
    puts "test_send_round_mems #{game.id}"
    Thread.new do
      sleep(1.5)

      round = Round.find_by(game_id: game.id, round_num: game.current_round)

      mems = Mem.pluck(:name)
      # mems = ["zhestko"]

      game.participants.times do |i|
        if  round["mem_#{i}_name"] == ""
          round.update("mem_#{i}_name": mems.sample(1)[0], "mem_#{i}_time": Time.now.to_f)
        end
      end
    end
  end
end
