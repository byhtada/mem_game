# frozen_string_literal: true

namespace :queue do
  desc "Показать статус очередей"
  task status: :environment do
    require_relative '../delayed_job_monitor'
    DelayedJobMonitor.status
  end

  desc "Очистить все очереди"
  task clear: :environment do
    require_relative '../delayed_job_monitor'
    DelayedJobMonitor.clear_all
  end

  desc "Очистить только неудачные задачи"
  task clear_failed: :environment do
    require_relative '../delayed_job_monitor'
    DelayedJobMonitor.clear_failed
  end

  desc "Перезапустить неудачные задачи"
  task retry_failed: :environment do
    require_relative '../delayed_job_monitor'
    DelayedJobMonitor.retry_failed
  end

  desc "Показать детали о задержанных задачах"
  task delayed: :environment do
    puts "📅 Запланированные задачи в Delayed Job:"
    
    upcoming = Delayed::Job.where('run_at > ?', Time.current).order(:run_at)
    
    if upcoming.any?
      upcoming.each do |job|
        job_class = job.handler.match(/job_class: (\w+)/)&.captures&.first || 'Unknown'
        delay = job.run_at - Time.current
        puts "#{job_class}"
        puts "  Запланировано на: #{job.run_at}"
        puts "  Задержка: #{delay.round(2)} секунд"
        puts "  ID: #{job.id}"
        puts ""
      end
    else
      puts "Нет запланированных задач"
    end
  end
end 