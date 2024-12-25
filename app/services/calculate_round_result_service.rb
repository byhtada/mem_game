class CalculateRoundResultService
  def initialize(game)
    @game = game
  end

  def call
    round = Round.find_by(game_id: @game.id, round_num: @game.current_round)
    users = @game.users

    users.each do |user|
      round_points = round["mem_#{user.game_user_number}_votes"]
      user.update(game_points: user.game_points + round_points)
    end
  end
end
