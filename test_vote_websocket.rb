#!/usr/bin/env ruby

require_relative 'config/environment'

puts "🔧 Testing VoteChannel WebSocket functionality..."

# Создаем тестового пользователя
user = User.find_or_create_by(tg_id: 67890) do |u|
  u.name = "TestVoteUser"
  u.ava = 30
  u.energy = 200
  u.coins = 100
end

puts "👤 User created: #{user.id} (#{user.name})"

# Создаем игру
game = Game.create!(
  participants: 3,
  uniq_id: Game.get_uniq_id,
  state: 'playing', # Устанавливаем состояние игры как 'playing'
  current_round: 1
)

puts "🎮 Game created: #{game.id} (#{game.uniq_id}) state: #{game.state}"

# Добавляем пользователей в игру
3.times do |i|
  test_user = User.find_or_create_by(tg_id: 70000 + i) do |u|
    u.name = "TestUser#{i + 1}"
    u.ava = 10 + i
    u.energy = 200
    u.coins = 50
  end

  game_user = GameUser.create!(
    game: game,
    user: test_user,
    game_user_number: i,
    mem_names: [
      {name: "zhestko", active: false},
      {name: "aeroflot", active: false}
    ].to_json
  )
  
  puts "👥 GameUser created: #{game_user.id} for user #{test_user.name}"
end

# Создаем раунд в состоянии голосования
round = Round.create!(
  game: game,
  round_num: 1,
  state: 'vote', # Устанавливаем состояние раунда как 'vote'
  question_text: "Тестовый вопрос для голосования",
  start_voting: Time.now.to_i,
  # Добавляем тестовые мемы для голосования
  mem_0_name: "zhestko",
  mem_0_time: Time.now.to_f - 10,
  mem_0_votes: 0,
  mem_1_name: "aeroflot", 
  mem_1_time: Time.now.to_f - 8,
  mem_1_votes: 1,
  mem_2_name: "lavochka_zakrita",
  mem_2_time: Time.now.to_f - 5,
  mem_2_votes: 0
)

puts "🎯 Round created: #{round.id} (question: #{round.question_text})"
puts "⏰ Round state: #{round.state}"
puts "🗳️ Voting started at: #{Time.at(round.start_voting)}"

# Проверяем голосование (это должно вызвать broadcast)
puts "\n📤 Testing vote casting (should trigger WebSocket broadcast)..."
puts "Current votes: mem_0: #{round.mem_0_votes}, mem_1: #{round.mem_1_votes}, mem_2: #{round.mem_2_votes}"

# Добавляем голос
round.update(mem_0_votes: round.mem_0_votes + 1)

puts "✅ Vote cast! Check Rails logs for WebSocket activity!"
puts "\n📝 Game ID: #{game.id} - use this in browser console to test VoteChannel"
puts "📝 User ID: #{user.id} - use this for WebSocket authentication"
puts "📝 Round ID: #{round.id}"

puts "\n🔍 Round state after vote:"
puts "- Round state: #{round.reload.state}"
puts "- Vote progress: #{round.vote_progress_wait}%"
puts "- Votes: mem_0: #{round.mem_0_votes}, mem_1: #{round.mem_1_votes}, mem_2: #{round.mem_2_votes}"
puts "- Start voting time: #{round.start_voting}" 