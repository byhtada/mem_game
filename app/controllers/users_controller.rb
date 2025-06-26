# frozen_string_literal: true

class UsersController < ApplicationController
  
  puts "USERS_CONTROLLER"
  def get_user_data
    render json: { user: @user, constants: get_constants }
  end

  def save_user_data
    @user.update(name: params[:name], ava: params[:ava])
    render json: { user: @user }
  end

  def update_energy
    energy = params[:energy]
    energy = @user.energy_max if energy > @user.energy_max

    @user.update(energy: energy)

    render json: {energy: @user.energy }
  end
  
  def register_in_tournament
    if UserFriend.where(user_id: @user.id).count < 3
      render json: {error: 'Сначала нужно пригласить 3х друзей'}
    else
      @user.update(registered_in_tournament: true)
      render json: { user: @user }
    end
  end

  def convert_energy
    if @user.energy < 50
      render json: {error: 'Недостаточно энергии'}
    else
      @user.update(coins: @user.coins + 4, energy: @user.energy - 50)
      render json: { user: @user }
    end
  end

  def get_user_friends
    friends = []
    UserFriend.where(user_id: @user.id).order(created_at: :asc).each do |uf|
      friend = User.find(uf.friend_id)

      friends << {
        name: friend.name,
        ava:  friend.ava,
        date: uf.created_at.strftime('%d.%m.%y')
      }
    end

    render json: {friends: friends}
  end

  private

  def get_constants
    {
      round_duration: ::Round::ROUND_DURATION * 1000,
      vote_duration: ::Round::VOTE_DURATION * 1000,
      restart_duration: ::Game::READY_TO_RESTART_DURATION * 1000
    }
  end
end
