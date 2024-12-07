class GamesController < ApplicationController

    def start_game
        game = Game.create
        game.update(participants: params[:participants])
    
        game.update(uniq_id:  get_game_code(@user))
        game_user = GameUser.create(user_id: @user.id,
                                    user_name: @user.name,
                                    user_ava: @user.ava,
                                    game_id: game.id,
                                    ready: false,
                                    admin: true,
                                    mem_names: get_mems_for_game)
    
        Thread.new do
          sleep(1.5)
          test_add_user_to_game(game, "Oleg")
    
          if params[:participants] >= 3
            sleep(1.5)
            test_add_user_to_game(game, "Anya")
          end
    
          if params[:participants] >= 4
            sleep(1.5)
            test_add_user_to_game(game, "Anton")
          end
    
          if params[:participants] >= 5
            sleep(1.5)
            test_add_user_to_game(game, "Vladimir Putin")
          end
    
        end
    
        render json: {game: game, admin: game_user.admin, user_id: @user.id}
    end

    def join_to_game
        game = Game.find_by(uniq_id: params[:game_code])
    
        game_user = GameUser.create(user_id:     @user.id,
                                       user_name:      @user.name,
                                       user_ava: @user.ava,
                                       game_id: game.id,
                                       ready: true,
                                       admin: true,
                                       mem_names: get_mems_for_game)
    
        render json: {game: game, admin: game_user.admin, user_id: @user.id}
    end
    
    
    def get_update_game_ready
        game = Game.find(params[:game_id])
        users = game.users
    
        if game.ready_to_start
            users.each_with_index do |user, i|
                user.update(game_user_number: i)
            end
      
            game.create_round
        end
        
        render json: {
          ready_to_start: game.ready_to_start,
          admin:          true,
          users:          users,
          game:           game,
          my_mems:        [],
        }
    end
    
    def ready_for_game
        GameUser.find_by(game_id: params[:game_id], user_id: @user.id).update(ready: true)
    
        Thread.new do
          sleep(1)
          GameUser.where(game_id: params[:game_id]).first.update(ready: true)
          sleep(1)
          GameUser.where(game_id: params[:game_id]).second.update(ready: true)
          sleep(1)
          GameUser.where(game_id: params[:game_id]).update_all(ready: true)
        end
    
    
        render json: {}
    end
    
    def get_game_winner
        game = Game.find(params[:game_id])
        users = get_game_users(game, true)
        winner = GameUser.where(game_id: params[:game_id]).sort{|f,s| f.game_points <=> s.game_points}.last
    
        render json: {
          users: users,
          winner_id: winner.user_id
        }
    end


    def create_test_game
        game = Game.create
        game.update(participants: 2)
    
        user = User.find_by(name: "Oleg")
    
        game.update(uniq_id: get_game_code(user) )
        game_user = GameUser.create(user_id:     user.id,
                                    user_name:   user.name,
                                    user_ava: user.ava,
                                    game_id: game.id,
                                    ready: true,
                                    admin: true,
                                    mem_names: get_mems_for_game)
    
        render json: {game_code: game.uniq_id}
    end

    private

    def test_add_user_to_game(game, name)
        mem_user = User.find_by(name: name)
    
        game_user = GameUser.create(user_id:     mem_user.id,
                                       user_name:   mem_user.name,
                                       user_ava: mem_user.ava,
                                       game_id:  game.id,
                                       mem_names:    get_mems_for_game)
        Thread.new do
          sleep(2)
          game_user.update(ready: true)
        end
    end
    
    def get_mems_for_game
        names = Mem.pluck(:name).sample(3)
        mem_names = []
        names.each do |m|
          mem_names.append({name: m, active: true})
        end
        JSON.dump(mem_names)
    end

    def get_game_code(user)
        (Time.now.to_i.to_s.last(3) + user.id.to_s).to_i
    end    
end
