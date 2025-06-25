#!/usr/bin/env ruby

require_relative 'config/environment'

puts "🔧 Testing RoundChannel WebSocket functionality..."

# Создаем тестового пользователя
user = User.find_or_create_by(tg_id: 54321) do |u|
  u.name = "TestRoundUser"
  u.ava = 25
  u.energy = 200
  u.coins = 100
end

puts "👤 User created: #{user.id} (#{user.name})"

# Создаем игру
game = Game.create!(
  participants: 2,
  uniq_id: Game.get_uniq_id,
  state: 'playing', # Устанавливаем состояние игры как 'playing'
  current_round: 1
)

puts "🎮 Game created: #{game.id} (#{game.uniq_id}) state: #{game.state}"

# Добавляем пользователя в игру
game_user = GameUser.create!(
  game: game,
  user: user,
  game_user_number: 0,
  mem_names: [
    {name: "zhestko", active: true},
    {name: "aeroflot", active: true}
  ].to_json
)

puts "👥 GameUser created: #{game_user.id}"

# Создаем раунд
round = Round.create!(
  game: game,
  round_num: 1,
  state: 'play',
  question_text: "Тестовый вопрос раунда"
)

puts "🎯 Round created: #{round.id} (question: #{round.question_text})"

# Проверяем отправку мема (это должно вызвать broadcast)
puts "\n📤 Testing mem sending (should trigger WebSocket broadcast)..."
round.send_mem(user.id, "zhestko")

puts "✅ Mem sent! Check Rails logs for WebSocket activity!"
puts "\n📝 Game ID: #{game.id} - use this in browser console to test RoundChannel"
puts "📝 User ID: #{user.id} - use this for WebSocket authentication"
puts "📝 Round ID: #{round.id}"

puts "\n🔍 Round state after mem send:"
puts "- Mem 0 name: #{round.reload.mem_0_name}"
puts "- Mem 0 time: #{round.mem_0_time}"
puts "- Round state: #{round.state}"
puts "- Round progress: #{round.round_progress_wait}%" 