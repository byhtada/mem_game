class GamesController < ApplicationController
    def find_game
        game = Game.where(state: 'registration', private: false).sample

        if game.nil?
            game = Game.create(participants: 4)
           # game = Game.create(participants: 4)
        end

        if game.join_to_game(@user)
            render json: {game: game, user_id: @user.id}
        else
            render json: { error: 'Недостаточно энергии' }
        end
    end

    def create_game
        game = Game.create(
            private: true,
            participants: params[:participants],
            uniq_id:  Game.get_uniq_id
        )

        if game.join_to_game(@user)
            render json: {game: game, user_id: @user.id}
        else
            render json: { error: 'Недостаточно энергии' }
        end
    end

    def join_to_game
        game = Game.find_by(uniq_id: params[:game_code], state: 'registration', private: true)
    
        if game.present?
            if game.join_to_game(@user)
                render json: {game: game, user_id: @user.id}
            else
                render json: { error: 'Недостаточно энергии' }
            end
        else
            render json: {error: 'Игра не найдена'}
        end
    end
    
    def get_game_winner
        game = Game.find(params[:game_id])
        users = game.users
        winners = game.winners
        #winner = GameUser.where(game_id: game.id).sort{|f,s| f.game_points <=> s.game_points}.last
    
        render json: {
          users: users,
          winners_ids: winners.pluck(:game_user_number),
          winners_names: winners.pluck(:user_name).join(', ')
        }
    end

    def ready_to_restart
        if @user.energy < 75
            render json: {error: 'Недостаточно энергии'}
        else
            game = Game.find(params[:game_id])
            game_user = GameUser.find_by(user_id: @user.id, game_id: game.id)
            game_user.update(ready_to_restart: true)
            
            game.broadcast_restart_update
    
            render json: {}
        end
    end
end
