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
    
    def get_update_game_ready
        game = Game.find(params[:game_id])
        users = GameUsersService.new(game, @user).call
    
        game.add_bot
        
        render json: {
          ready_to_start: game.ready_to_start,
          ready_progress_wait: game.ready_progress_wait,
          users:          users,
          game:           game,
          my_mems:        [],
        }
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

    def get_restart_update
        game = Game.find(params[:game_id])
        users = GameUsersService.new(game, @user).call

        restart_progress_wait = game.restart_progress_wait
        new_game = nil

        if restart_progress_wait.negative? || game.users.select {|u| u.ready_to_restart}.count == game.participants
            if game.state != 'close'
                new_game = Game.create(participants: 4)

                game.users.each do |user|
                    next unless user.ready_to_restart

                    new_game.join_to_game(User.find(user.user_id))
                end
                
                game.update(state: 'close')
                new_game.update(state: 'playing') if new_game.participants == new_game.users.count
            end
        end

        new_game = Game.find(GameUser.where(user_id: @user.id).last.game_id)

        render json: {
            restart_progress_wait: restart_progress_wait,
            ready_to_start: game.reload.state == 'close',
            users: users,
            new_game: new_game,
            game: game,
            user_id: @user.id,
            winners_ids: game.winners.pluck(:game_user_number),
        }
    end

    def ready_to_restart
        if @user.energy < 75
            render json: {error: 'Недостаточно энергии'}
        else
            game = Game.find(params[:game_id])
            game_user = GameUser.find_by(user_id: @user.id, game_id: game.id)
            game_user.update(ready_to_restart: true)
    
            render json: {}
        end
    end
end
