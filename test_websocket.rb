#!/usr/bin/env ruby

require_relative 'config/environment'

puts "🔧 Creating test user and game..."

# Создаем тестового пользователя
user = User.find_or_create_by(tg_id: 12345) do |u|
  u.name = "TestUser"
  u.ava = 20
  u.energy = 200
  u.coins = 100
end

puts "👤 User created: #{user.id} (#{user.name})"

# Создаем игру
game = Game.create!(
  participants: 3,
  uniq_id: Game.get_uniq_id,
  state: 'registration'
)

puts "🎮 Game created: #{game.id} (#{game.uniq_id})"

# Добавляем пользователя в игру
result = game.join_to_game(user)

puts "🎯 User joined game: #{result}"
puts "👥 Game users count: #{game.game_users.count}/#{game.participants}"
puts "✅ Ready to start: #{game.ready_to_start}"

puts "\n🔍 Check Rails logs for WebSocket activity!"
puts "📝 Game ID: #{game.id} - use this in browser console" 