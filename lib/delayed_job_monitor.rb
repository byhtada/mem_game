# frozen_string_literal: true

class DelayedJobMonitor
  def self.status
    puts "📊 Статистика Delayed Job:"
    puts "Всего задач в очереди: #{Delayed::Job.count}"
    puts "Ожидающих выполнения: #{Delayed::Job.where('run_at <= ?', Time.current).count}"
    puts "Запланированных на будущее: #{Delayed::Job.where('run_at > ?', Time.current).count}"
    puts "Неудачных попыток: #{Delayed::Job.where('attempts > 0').count}"
    puts "Заблокированных: #{Delayed::Job.where('locked_at IS NOT NULL').count}"
    puts ""
    
    puts "�� Задачи по типам:"
    
    # Упрощенный способ подсчета задач по типам
    types = {}
    Delayed::Job.all.each do |job|
      begin
        handler = YAML.load(job.handler)
        job_class = handler.class.name if handler.respond_to?(:class)
        types[job_class] ||= 0
        types[job_class] += 1
      rescue => e
        types['Unknown'] ||= 0
        types['Unknown'] += 1
      end
    end
    
    if types.empty?
      puts "  Нет активных задач"
    else
      types.each do |type, count|
        puts "  #{type}: #{count}"
      end
    end
    puts ""
    
    puts "🔄 Ближайшие запланированные задачи:"
    upcoming = Delayed::Job.where('run_at > ?', Time.current).order(:run_at).limit(10)
    if upcoming.any?
      upcoming.each do |job|
        job_class = extract_job_class(job.handler)
        delay = job.run_at - Time.current
        puts "#{job_class} - через #{delay.round(2)} секунд (#{job.run_at})"
      end
    else
      puts "Нет запланированных задач"
    end
    puts ""
    
    puts "⚠️ Проблемные задачи:"
    failed = Delayed::Job.where('attempts > 0')
    if failed.any?
      failed.each do |job|
        job_class = extract_job_class(job.handler)
        puts "#{job_class} - попыток: #{job.attempts}, последняя ошибка: #{job.last_error&.split("\n")&.first}"
      end
    else
      puts "Проблемных задач нет"
    end
  end
  
  def self.clear_all
    count = Delayed::Job.count
    Delayed::Job.delete_all
    puts "🧹 Удалено #{count} задач из очереди!"
  end
  
  def self.clear_failed
    count = Delayed::Job.where('attempts > 0').count
    Delayed::Job.where('attempts > 0').delete_all
    puts "🧹 Удалено #{count} неудачных задач!"
  end
  
  def self.retry_failed
    failed = Delayed::Job.where('attempts > 0')
    count = failed.count
    failed.update_all(attempts: 0, run_at: Time.current, locked_at: nil, locked_by: nil)
    puts "♻️ Перезапущено #{count} неудачных задач"
  end
  
  def self.delayed_jobs
    puts "⏰ Отложенные задачи:"
    future_jobs = Delayed::Job.where('run_at > ?', Time.current).order(:run_at)
    
    if future_jobs.empty?
      puts "  Нет отложенных задач"
    else
      future_jobs.each do |job|
        begin
          handler = YAML.load(job.handler)
          job_class = handler.class.name if handler.respond_to?(:class)
          puts "  #{job_class} - запланирована на #{job.run_at} (через #{time_until(job.run_at)})"
        rescue => e
          puts "  Неизвестная задача - запланирована на #{job.run_at}"
        end
      end
    end
  end
  
  private
  
  def self.extract_job_class(handler)
    match = handler.match(/job_class: (\w+)/)
    match ? match[1] : 'Unknown'
  rescue
    'Unknown'
  end
  
  def self.time_until(time)
    diff = time - Time.current
    if diff < 60
      "#{diff.round} сек"
    elsif diff < 3600
      "#{(diff / 60).round} мин"
    else
      "#{(diff / 3600).round} ч"
    end
  end
end 