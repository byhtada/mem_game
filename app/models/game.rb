# frozen_string_literal: true

class Game < ApplicationRecord
  ROUNDS = 1
  READY_TO_START_DURATION = 10
  READY_TO_RESTART_DURATION = 10

  has_many :rounds, dependent: :destroy
  has_many :game_users, dependent: :destroy

  enum state: {
    registration: 'registration',
    playing: 'playing',
    finishing: 'finishing',
    close: 'close'
  }

  after_create :add_bot

  def ready_progress_wait
    100 - (100 * (Time.now.to_i - self.updated_at.to_i).to_f / READY_TO_START_DURATION).to_i
  end

  def restart_progress_wait
    100 - (100 * (Time.now.to_i - self.updated_at.to_i).to_f / READY_TO_RESTART_DURATION).to_i
  end

  def add_bot
    BotJoinGameJob.set(wait: (READY_TO_START_DURATION * 0.3).seconds).perform_later(self.id)
    BotJoinGameJob.set(wait: (READY_TO_START_DURATION * 0.6).seconds).perform_later(self.id)
    BotJoinGameJob.set(wait: (READY_TO_START_DURATION * 0.8).seconds).perform_later(self.id)
  end

  def join_to_game(user)
    Rails.logger.info "🎮 [Game#join_to_game] User #{user.id} (#{user.name}) joining game #{id}"
    
    return false if user.energy - 5 < 0
    user.update(energy: user.energy - 5)

    game_user = GameUser.create(
      user_id:    user.id,
      user_name:  user.name,
      user_ava:   user.ava,
      bot:        user.bot,
      game_id:    self.id,
      mem_names:  MemForGameService.call)

    Rails.logger.info "🎮 [Game#join_to_game] Created GameUser #{game_user.id} for user #{user.id}"
    Rails.logger.info "🎮 [Game#join_to_game] Game #{id} now has #{game_users.count}/#{participants} players"

    # Отправляем обновление всем подписчикам после добавления игрока

    broadcast_game_update

    if self.game_users.count == self.participants
      Rails.logger.info "🎮 [Game#join_to_game] Game #{id} is full, starting game!"
      self.start_game
    end

    true
  end

  def start_game
    if self.game_users.where(bot: true).count == self.participants
      self.destroy
      return
    end

    self.game_users.order(created_at: :asc).each_with_index do |user, i|
      user.update(game_user_number: i)
    end

    self.update(state: 'playing')
    self.create_round
  end

  def ready_to_start
    self.participants == self.game_users.count
  end

  def users
    users = self.game_users
    users.sort{|f,s| f.created_at <=> s.created_at}
  end

  def create_round
    new_round = self.current_round + 1

    self.update(current_round: new_round)
    round = Round.create(game_id: self.id,
                         question_text: Question.pluck(:text).sample(1)[0],
                         round_num: new_round)

    self.game_users.where(bot: true).each do |game_user|
      min = ::Round::ROUND_DURATION * 0.2
      max = ::Round::ROUND_DURATION * 0.5
      delay = rand(min..max)

      Rails.logger.info "🎮 [Game#create_round] BotRoundJob delay: #{delay.seconds} seconds"
      BotRoundJob.set(wait: delay.seconds).perform_later(round.id, game_user.id)
    end

    RoundClearJob.set(wait: ::Round::ROUND_DURATION).perform_later(self.id, self.current_round)
  end

  def winners
    max_points = GameUser.where(game_id: self.id).sort{|f,s| f.game_points <=> s.game_points}.last.game_points

    GameUser.where(game_id: self.id, game_points: max_points)
  end
  
  def finish_game
    self.update(state: 'finishing')

    winners_ids = self.winners.pluck(:user_id)
    winner_points = (50 / winners_ids.count).to_i
    lose_points = 10

    self.game_users.each do |game_user|
      user = User.find(game_user.user_id)
      winner_points = winner_points * 3 if user.premium
      lose_points = 30 if user.premium

      add_coins = winners_ids.include?(user.id) ? winner_points : lose_points

      user.update(coins: user.coins + add_coins)
      
      self.game_users.where(bot: true).each do |game_user|
        min = READY_TO_RESTART_DURATION * 0.2
        max = READY_TO_RESTART_DURATION * 0.8
        delay = rand(min..max)
        BotRestartJob.set(wait: delay.seconds).perform_later(self.id, game_user.id)
      end
    end

    GameRestartJob.set(wait: READY_TO_RESTART_DURATION).perform_later(self.id)
  end

  def self.get_uniq_id
    ids = Game.where(state: %w[registration]).select(:uniq_id).pluck(:uniq_id)
    code = nil

    while code == nil
        num = rand(1000..9999)
        code = num if ids.exclude?(num)
    end

    code
  end

  # Методы для веб-сокет broadcasting
  def broadcast_game_update
    # Отправляем обновления только для игр в состоянии регистрации
    Rails.logger.info "🎮 [Game#broadcast_game_update] Game #{id} state: #{state}"
    return unless state == 'registration'
    
    data = build_game_update_data
    Rails.logger.info "🎮 [Game#broadcast_game_update] Broadcasting to Game #{id}: #{data.inspect}"
    GameChannel.broadcast_to(self, data)
    Rails.logger.info "🎮 [Game#broadcast_game_update] Broadcast completed for Game #{id}"
  end

  def broadcast_restart_update
    # Отправляем обновления для игр в состоянии finishing (после завершения игры)
    Rails.logger.info "🔄 [Game#broadcast_restart_update] Game #{id} state: #{state}"
    return unless state == 'finishing'
    
    data = build_restart_update_data
    Rails.logger.info "🔄 [Game#broadcast_restart_update] Broadcasting restart to Game #{id}: #{data.inspect}"
    RestartChannel.broadcast_to(self, data)
    Rails.logger.info "🔄 [Game#broadcast_restart_update] Restart broadcast completed for Game #{id}"
  end

  private

  def build_game_update_data
    {
      ready_to_start: ready_to_start,
      ready_progress_wait: ready_progress_wait,
      users: users_for_broadcast,
      game: self.as_json,
      my_mems: []
    }
  end

  def build_restart_update_data
    new_game = nil

    ids_ready_to_restart = self.users.select {|u| u.ready_to_restart}.pluck(:user_id)

    # Логика рестарта (из контроллера)
    if restart_progress_wait.negative? || ids_ready_to_restart.count == self.participants
      if self.state != 'close'
        new_game = Game.create(participants: 4)

        self.users.each do |user|
          next unless user.ready_to_restart

          new_game.join_to_game(User.find(user.user_id))
        end
        
        self.update(state: 'close')
        new_game.start_game if new_game.participants == new_game.users.count
      end
    end

    {
      restart_progress_left: (Game::READY_TO_RESTART_DURATION - (Time.now.to_i - self.updated_at.to_i)) * 1000,
      restart_progress_wait: restart_progress_wait,
      ready_to_start: reload.state == 'close',
      users: users_for_broadcast,
      new_game: new_game&.as_json,
      new_game_users: new_game&.users&.pluck(:user_id),
      game: self.as_json,
      winners_ids: winners.pluck(:game_user_number),
    }
  end

  def users_for_broadcast
    # Используем ту же логику, что и в методе users, с сортировкой
    game_users.reload.order(:created_at).map do |game_user|
      {
        user_id: game_user.user_id,
        user_name: game_user.user_name,
        user_ava: game_user.user_ava,
        game_user_number: game_user.game_user_number,
        game_points: game_user.game_points,
        ready_to_restart: game_user.ready_to_restart,
        bot: game_user.bot
      }
    end
  end
end
