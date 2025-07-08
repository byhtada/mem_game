class AiQuestionContextService
  OPENAI_API_KEY = ENV['OPENAI_API_KEY']

  def initialize(question)
    @question = question
  end

  def call
    all_emotions = []
    workbook = Roo::Spreadsheet.open './files/Вопросы к мемам.xlsx'
  
    rows = workbook.sheet('Лист1')
  
    rows.each_row_streaming do |row|
      row_cells = row.map { |cell| cell.value }
  
      next if row_cells[0] == "Фильтр"
      return unless row_cells[0].present?
  
     # context = get_context(row_cells[2])
      all_emotions << row_cells[3]
    end
    puts "Questions created"

    result = {}
    all_emotions.each do |emotion|
      result[emotion] = 0  if result[emotion].blank?
      result[emotion] += 1 
    end

    result = result.sort_by { |_, count| -count }

    puts result.to_s

    result.each do |emotion, count|
      puts emotion if count > 10
    end
  end

  def get_context(question)
    content = "Есть вопрос: #{question}. Напиши 1 тэгов на английском описывающий эмоцию вопроса. В ответе только тэг"

    response = HTTParty.post(
      'https://api.openai.com/v1/chat/completions',
      headers: {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{OPENAI_API_KEY}"
      },
      body: {
        model: 'gpt-4.1',
        store: true,
        messages: [
          { role: 'user', content:  }
        ]
      }.to_json
    )

    result = response.parsed_response["choices"][0]["message"]["content"]
  end
end
