class ApplicationController < ActionController::API
    include ActionController::HttpAuthentication::Basic::ControllerMethods
    include ActionController::HttpAuthentication::Token::ControllerMethods

    
    before_action :authenticate_user_from_token


  
  
    private
  
    # TODO вынести в модель
    def get_game_users(game, with_current_user)
      users = []
      if with_current_user
        users = GameUser.where(game_id: game.id)
      else
        users = GameUser.where(game_id: game.id).where.not(user_id: @user.id)
      end
      users = GameUser.where(game_id: game.id).where.not(user_id: @user.id)
      users.sort{|f,s| f.created_at <=> s.created_at}
      users = users.to_a.unshift(GameUser.find_by(game_id: game.id, user_id: @user.id))
      users
    end
  
  
  
    def authenticate_user_from_token
        unless authenticate_with_http_token { |token, options|  User.find_by(auth_token: token); puts "token #{token} id #{User.find_by(auth_token: token)}"; @user = User.find_by(auth_token: token)}
    
          render json: { error: 'Bad Token'}, status: 401
        end
    end
  

end
