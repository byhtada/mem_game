class GameUsersService
  def initialize(game, current_user)
    @game = game
    @current_user = current_user
  end

  def call
    users = @game.game_users.sort_by(&:created_at)
    me = users.find { |user| user.user_id == @current_user.id }
    users = users - [me]
    users.unshift(me)
    users.delete(nil)
    users
  end
end