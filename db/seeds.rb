@avatars = [1,2,10,11,13,15,17,20,29,32,37,42,43,50,51,
  54,57,62,70,75,
  77,85,88,105,114
 ]

User.all.destroy_all
user = User.create(name: "Sanya", ava: @avatars.sample(1).first)
user.update(auth_token: "123", tg_id: 317600571)


# Создаем ботов с интересными именами
200.times do |i|
  bot_names = [
    Faker::Games::Pokemon.name,
    Faker::Games::Dota.hero,
    Faker::Games::ElderScrolls.name,
    Faker::Games::Minecraft.mob,
    Faker::Games::WorldOfWarcraft.hero,
    Faker::Superhero.name,
    Faker::Internet.username,
    Faker::Internet.username,
    Faker::Internet.username,
    Faker::Internet.username,
    Faker::Internet.username
  ]

  bot_name = bot_names.sample

  case rand(0..40)
  when 0..10
    bot_name = bot_name.gsub(' ', '_').downcase
  when 11..20
    bot_name = bot_name.gsub(' ', '_').upcase
  when 21..30
    bot_name = bot_name.capitalize.gsub(' ', '')
  when 31..40
    bot_name = bot_name
  end
  
  User.create(
    name: bot_name, 
    ava: @avatars.sample(1).first, 
    bot: true
  )
end

def create_questions
  workbook = Roo::Spreadsheet.open './files/Вопросы к мемам.xlsx'
  
  rows = workbook.sheet('Лист1')

  rows.each_row_streaming do |row|
    row_cells = row.map { |cell| cell.value }

    next if row_cells[0] == "Фильтр"
    return unless row_cells[0].present?

    Question.create(
      style: row_cells[1],
      adult: row_cells[0] == "18+",
      text:  row_cells[2],
      context: row_cells[3]
      )
  end
  puts "Questions created"
end


def upload_mems
  mems = JSON.parse(File.read('./files/perfect_mem_results.json'))

  mems.each do |mem|
    file_name = mem['file_name'].split(".mp4")[0]
    Mem.create(
      name: file_name,
      name_ru: mem['mem_name_ru'],

      link_image: "https://s3.regru.cloud/mem-assets/covers/#{file_name}.webp",
      link_video: "https://s3.regru.cloud/mem-assets/videos/#{file_name}.mp4",

      context: mem['context']
    )
  end
end


Question.all.destroy_all
Mem.all.destroy_all

create_questions
upload_mems