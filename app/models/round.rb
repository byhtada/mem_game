# frozen_string_literal: true

class Round < ApplicationRecord
  belongs_to :game

  validates :round_num, uniqueness: { scope: :game_id }
end
