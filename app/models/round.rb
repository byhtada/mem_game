# frozen_string_literal: true

class Round < ApplicationRecord
  belongs_to :game

  enum state: {
    play: 'play',
    vote: 'vote',
    close: 'close'
  }

  validates :round_num, uniqueness: { scope: :game_id }
end
