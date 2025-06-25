class BotJoinGameJob < ApplicationJob
  queue_as :bot_join_sequential

  def perform(game_id)
    game = Game.find(game_id)
    game_users = game.game_users

    add = false
    add = true if game_users.count == 1 && game.ready_progress_wait < 70
    add = true if game_users.count == 2 && game.ready_progress_wait < 40
    add = true if game_users.count == 3 && game.ready_progress_wait < 30

    if add && game_users.count < game.participants
      bot = User.where(bot: true).where.not(id: game_users.pluck(:user_id)).sample
      if bot.present?
        bot.update(energy: bot.energy + 100)
        game.join_to_game(bot)
      end
    end
  end
end
