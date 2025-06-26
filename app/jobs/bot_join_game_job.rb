class BotJoinGameJob < ApplicationJob
  def perform(game_id)
    Rails.logger.info "🤖 [BotJoinGameJob] Starting job for game #{game_id}"
    game = Game.find(game_id)
    game_users = game.game_users

    add = false
    add = true if game_users.count == 1
    add = true if game_users.count == 2
    add = true if game_users.count == 3

    if add && game_users.count < game.participants
      bot = User.where(bot: true).where.not(id: game_users.pluck(:user_id)).sample
      if bot.present?
        bot.update(energy: bot.energy + 100)
        game.join_to_game(bot)
      end
    end
  end
end
