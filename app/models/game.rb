# frozen_string_literal: true

class Game < ApplicationRecord
  has_many :rounds
  has_many :game_users


  def ready_to_start
    ready_users = 0
    self.game_users.map { |u| ready_users += 1 if u.ready }
    
    self.participants == ready_users
  end

  def users
    users = self.game_users
    users.sort{|f,s| f.created_at <=> s.created_at}
    users
  end

  def create_round
    new_round = self.current_round + 1

    self.update(current_round: new_round)
    Round.create(game_id: self.id,
                 question_text: Question.pluck(:text).sample(1)[0],
                 round_num: new_round)
  end
end
