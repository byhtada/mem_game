# frozen_string_literal: true

class UsersController < ApplicationController
  
  def get_user_data
    render json: { user: @user }
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
end
