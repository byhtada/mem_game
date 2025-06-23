class TestController < ApplicationController


  def test_ready_for_game
    game = Game.last

    sleep(0.5)
    test_add_user_to_game(game, 2)

    if game.participants >= 3
      sleep(0.5)
      test_add_user_to_game(game, 3)
    end

    if game.participants >= 4
      sleep(0.5)
      test_add_user_to_game(game, 4)
    end
 
  end

  def test_send_round_mems
    game = Game.last
    round = Round.find_by(game_id: game.id, round_num: game.current_round)
    users = GameUsersService.new(game, @user).call
    sets_mems = params[:mems].split(',').map{|m| m = "mem_#{get_mem_number(m)}"}


    if sets_mems.length > 0
      n = 0
      5.times do |i|
         next unless round[:"mem_#{i}_name"] == ''

         user = users.select { |mem_game_user| mem_game_user.game_user_number == i }.first

         next unless user.present?

         round.update("mem_#{i}_name": sets_mems[n])
         round.update("mem_#{i}_time": Time.now.to_f)
         n += 1
      end
      
      return
    end

    afk_times = params[:afk].to_i
    5.times do |i|
      next unless round[:"mem_#{i}_name"] == ''

      user = users.select { |mem_game_user| mem_game_user.game_user_number == i }.first

      next unless user.present?

      afk_times -= 1
      next if afk_times >= 0

      active_mem = JSON.parse(user.mem_names).select { |mem| mem['active'] == true }.first

      round.update("mem_#{i}_name": active_mem['name'])
      round.update("mem_#{i}_time": Time.now.to_f)


      new_user_mems = []
      JSON.parse(user.mem_names).each do |mem|
        new_mem = { name: mem['name'], active: mem['active'] }
        new_mem[:active] = false if active_mem['name'] == mem['name']
        new_user_mems.append(new_mem)
      end

      if user.user_id != @user.id
        user.update(mem_names: JSON.dump(new_user_mems))
      end
    end

    round.update(created_at: Time.now - 3.minutes)
  end

  def test_round_vote
    game = Game.last
    round = Round.find_by(game_id: game.id, round_num: game.current_round)

    total_votes = 0
    5.times do |i|
      total_votes += round["mem_#{i}_votes"]
    end

    (game.participants - total_votes).times do |_i|
      vote_for_user = game.users.pluck(:game_user_number).sample
      current_votes = round["mem_#{vote_for_user}_votes"]
      round.update("mem_#{vote_for_user}_votes": current_votes + 1)
    end

    CalculateRoundResultService.new(game).call
    if (game.current_round >= 3) == false
      game.create_round
      finish_game = false
    end

    round.update(start_voting: Time.now - 5.minutes)

  end

  def test_round_change_question
    Round.last.update(question_text: params[:question_text])
  end

  def test_create_private_game
    game = Game.create(private: true, uniq_id: Game.get_uniq_id)
    test_add_user_to_game(game, 2)
    test_add_user_to_game(game, 3)
    test_add_user_to_game(game, 4)

    render json: { game_code: game.uniq_id }
  end

  def update_mems
    ignored = [9]

    i = 0
    while i < params[:last_num].to_i
      i += 1
      next if ignored.include? (i)

      mem_name = "mem_#{num.to_s.rjust(3, '0')}"

      if Mem.find_by(name: mem_name).nil?
        Mem.create(name: mem_name)
      end      
    end
  end

  def test_update_names
    User.where(id: [2,3,4]).each_with_index do |u, i|
      u.update(name: params[:names].split(',')[i])
    end
  end
  private

  def get_mem_number(num)
    num.to_s.rjust(3, '0')
  end

  def test_add_user_to_game(game, id)
    mem_user = User.find(id)

    game.join_to_game(mem_user)
  end
end
