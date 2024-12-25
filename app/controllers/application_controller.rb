class ApplicationController < ActionController::API
    include ActionController::HttpAuthentication::Basic::ControllerMethods
    include ActionController::HttpAuthentication::Token::ControllerMethods

    
    before_action :authenticate_user_from_token

    private
  
  
  
    def authenticate_user_from_token
        unless authenticate_with_http_token { |token, options|  User.find_by(auth_token: token); puts "token #{token} id #{User.find_by(auth_token: token)}"; @user = User.find_by(auth_token: token)}
    
          render json: { error: 'Bad Token'}, status: 401
        end
    end
end
