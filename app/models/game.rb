# frozen_string_literal: true

class Game < ApplicationRecord
  has_many :rounds
  has_many :game_users

  enum state: {
    registration: 'registration',
    playing: 'playing',
    finishing: 'finishing',
    close: 'close'
  }

  def join_to_game(user)
    return false if user.energy - 50 < 0
    user.update(energy: user.energy - 50)

    GameUser.create(
      user_id:    user.id,
      user_name:  user.name,
      user_ava:   user.ava,
      game_id:    self.id,
      mem_names:  MemForGameService.call)

    if self.game_users.count == self.participants
      self.update(state: 'playing')
      self.create_round

      self.users.each_with_index do |user, i|
        user.update(game_user_number: i)
      end
    end
  end

  def ready_to_start
    self.participants == self.game_users.count
  end

  def users
    users = self.game_users
    users.sort{|f,s| f.created_at <=> s.created_at}
  end

  def create_round
    new_round = self.current_round + 1

    self.update(current_round: new_round)
    Round.create(game_id: self.id,
                 question_text: Question.pluck(:text).sample(1)[0],
                 round_num: new_round)
  end

  def self.get_uniq_id
    ids = Game.where(state: %w[registration]).select(:uniq_id).pluck(:uniq_id)
    code = nil

    while code == nil
        num = rand(1000..9999)
        code = num if ids.exclude?(num)
    end

    code
  end
end
