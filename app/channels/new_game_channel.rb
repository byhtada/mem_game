class NewGameChannel < ApplicationCable::Channel
  def subscribed
    begin
      game = Game.find(params[:game_id])      
      game_user = GameUser.find_by(game_id: game.id, user_id: current_user.id)
      
      if game_user.present?
        stream_for game
      else
        reject
      end
    rescue => e
      reject
    end
  end

  def unsubscribed
    Rails.logger.info "🔌 [GameChannel#unsubscribed] User #{current_user&.id} unsubscribed from game channel"
  end
end 