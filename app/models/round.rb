# frozen_string_literal: true

class Round < ApplicationRecord
  ROUND_DURATION = 30
  VOTE_DURATION = 10

  belongs_to :game

  enum state: {
    play: 'play',
    vote: 'vote',
    close: 'close'
  }

  validates :round_num, uniqueness: { scope: :game_id }

  def round_progress_wait
    100 - (100 * (Time.now.to_i - self.created_at.to_i).to_f / ROUND_DURATION).to_i
  end

  def vote_progress_wait
    100 - (100 * (Time.now.to_i - self.start_voting).to_f / VOTE_DURATION).to_i
  end

  def send_mem(user_id, mem_name)
    user_in_game = GameUser.find_by(game_id: self.game_id, user_id: user_id)
    user_number = user_in_game.game_user_number

    new_user_mems = []
    JSON.parse(user_in_game.mem_names).each do |mem|
      new_mem = { name: mem['name'], active: mem['active'] }
      new_mem[:active] = false if mem_name == mem['name']
      new_user_mems.append(new_mem)
    end
    user_in_game.update(mem_names: JSON.dump(new_user_mems))

    self.update("mem_#{user_number}_name": mem_name,
                 "mem_#{user_number}_time": Time.now.to_f)
  end
end
