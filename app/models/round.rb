# frozen_string_literal: true

class Round < ApplicationRecord
  ROUND_DURATION = 30
  VOTE_DURATION = 10

  belongs_to :game

  enum state: {
    play: 'play',
    vote: 'vote',
    close: 'close'
  }

  validates :round_num, uniqueness: { scope: :game_id }

  def round_progress_wait
    100 - (100 * (Time.now.to_i - self.created_at.to_i).to_f / ROUND_DURATION).to_i
  end

  def vote_progress_wait
    100 - (100 * (Time.now.to_i - self.reload.start_voting).to_f / VOTE_DURATION).to_i
  end

  def send_mem(user_id, mem_name)
    user_in_game = GameUser.find_by(game_id: self.game_id, user_id: user_id)
    user_number = user_in_game.game_user_number

    new_user_mems = []
    JSON.parse(user_in_game.mem_names).each do |mem|
      new_mem = { name: mem['name'], active: mem['active'] }
      new_mem[:active] = false if mem_name == mem['name']
      new_user_mems.append(new_mem)
    end
    user_in_game.update(mem_names: JSON.dump(new_user_mems))

    self.update("mem_#{user_number}_name": mem_name,
                 "mem_#{user_number}_time": Time.now.to_f)
    
    broadcast_round_update
    # завершение раунда
    #start_voting
  end

  def finish_voting
    # Атомарная проверка и завершение голосования для избежания дублирования
    self.reload
    # Проверяем, что голосование еще не завершено
    return if self.state == 'close'
    
    self.update!(state: 'close')
    CalculateRoundResultService.new(self.game).call

    if self.round_num >= Game::ROUNDS
      self.game.finish_game
    else
      self.game.create_round
    end

    self.broadcast_vote_update
  end

  def try_finish_voting
    # Атомарная проверка и завершение голосования
    self.reload
    users = self.game.game_users
    mems, total_votes = get_round_votes_for_broadcast(users)
    finish_round = total_votes >= self.game.participants

    if finish_round && self.state == 'vote'
      # Вся логика завершения в одной транзакции
      self.update!(state: 'close')
      CalculateRoundResultService.new(self.game).call

      if self.round_num >= Game::ROUNDS
        self.game.finish_game
      else
        self.game.create_round
      end
      
      # Broadcast происходит после завершения транзакции
      return true
    end
  end

  def try_finish_round
    self.reload
      mems, total_votes = get_round_votes_for_broadcast(self.game.users)

      if mems.count == self.game.participants && self.state == 'play'
        self.update!(state: 'vote')
      end
  end

  # Методы для веб-сокет broadcasting
  def broadcast_round_update
    # Отправляем обновления только для раундов в состоянии play и игр в состоянии playing
    Rails.logger.info "🎮 [Round#broadcast_round_update] Round #{id} state: #{state}, Game state: #{self.game.state}"
    return unless state == 'play' && self.game.state == 'playing'
    
    Rails.logger.info "🎮 [Round#broadcast_round_update] Broadcasting round update for game #{game_id}"
    try_finish_round
    RoundChannel.broadcast_to(self.game, build_round_update_data)
    Rails.logger.info "🎮 [Round#broadcast_round_update] Broadcast completed for round #{id}"
  end

  def broadcast_vote_update
    # Отправляем обновления только для раундов в состоянии vote и игр в состоянии playing
    Rails.logger.info "🎮 [Round#broadcast_vote_update] Round #{id} state: #{state}, Game state: #{self.game.state}"
    return unless state == 'vote' && self.game.state == 'playing'
    
    Rails.logger.info "🎮 [Round#broadcast_vote_update] Broadcasting vote update for game #{game_id}"
    
    # Пытаемся завершить голосование, если это произошло - отправляем финальный broadcast
    if try_finish_voting
      Rails.logger.info "🎮 [Round#broadcast_vote_update] Voting finished, sending final broadcast"
      VoteChannel.broadcast_to(self.game, build_vote_update_data)
    else
      # Обычный broadcast во время голосования
      VoteChannel.broadcast_to(self.game, build_vote_update_data)
    end
    
    Rails.logger.info "🎮 [Round#broadcast_vote_update] Broadcast completed for round #{id}"
  end

  def build_round_update_data
    users = self.game.users
    
    # Получаем мемы раунда
    mems = get_round_mems_for_broadcast(users)
    round_progress_wait = self.round_progress_wait
    
    ready_to_open = mems.length == self.game.participants
    
    # my_mems не включаем в broadcast, так как они индивидуальны для каждого пользователя
    {
      ready_to_open: ready_to_open,
      mems: mems,
      question: self.question_text,
      round: self,
      users: users,
      round_progress_wait: round_progress_wait,
      round_progress_left: (ROUND_DURATION - (Time.now.to_i - self.created_at.to_i)) * 1000
    }
  end

  def build_vote_update_data
    users = self.game.users
    
    # Получаем данные голосования
    Rails.logger.info "🎮 [Round#build_vote_update_data] Round #{self.inspect} "
    Rails.logger.info "🎮 [Round#build_vote_update_data] vote_progress_wait: #{self.vote_progress_wait}"

    vote_progress_wait = self.vote_progress_wait
    mems, total_votes = get_round_votes_for_broadcast(users)
    
    # Проверяем завершение голосования
    finish_game = false
    finish_round = total_votes >= self.game.participants || vote_progress_wait.negative?
    
    if finish_round
      if self.round_num >= Game::ROUNDS
        finish_game = true
      end
    end
    
    {
      mems: mems,
      round: self,
      users: self.game.users,
      vote_finish: finish_round,
      vote_progress_wait: vote_progress_wait,
      vote_progress_left: (VOTE_DURATION - (Time.now.to_i - self.start_voting.to_i)) * 1000,
      finish_game: finish_game
    }
  end

  private

  def get_round_mems_for_broadcast(users)
    mems = []
    5.times do |i|
      next if self[:"mem_#{i}_name"] == ''

      user = users.select { |mem_game_user| mem_game_user.game_user_number == i }.first
      mems.append({ mem: self[:"mem_#{i}_name"],
                    time: self[:"mem_#{i}_time"],
                    user_num: i,
                    user_id: user.user_id,
                    name: user.user_name,
                    avatar: user.user_ava })
    end

    mems.sort { |f, s| f[:time] <=> s[:time] }
  end

  def get_round_votes_for_broadcast(users)
    total_votes = 0

    mems = []
    5.times do |i|
      total_votes += self["mem_#{i}_votes"]

      next unless self["mem_#{i}_name"] != ''

      user = users.select { |mem_game_user| mem_game_user.game_user_number == i }.first
      mems.append({ mem: self["mem_#{i}_name"],
                    time: self["mem_#{i}_time"],
                    votes: self["mem_#{i}_votes"],
                    user_num: i,
                    user_id: user.user_id,
                    name: user.user_name,
                    avatar: user.user_ava })
    end

    mems = mems.sort { |f, s| f[:time] <=> s[:time] }

    [mems, total_votes]
  end
end
