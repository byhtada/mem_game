# Конфигурация Delayed Job для точного выполнения по времени

# Основные настройки
Delayed::Worker.destroy_failed_jobs = false  # Сохраняем неудачные задачи для отладки
Delayed::Worker.sleep_delay = 1              # Проверка каждую секунду = точное выполнение
Delayed::Worker.max_attempts = 3             # Максимум 3 попытки
Delayed::Worker.max_run_time = 5.minutes     # Таймаут выполнения
Delayed::Worker.default_queue_name = 'default'
Delayed::Worker.delay_jobs = !Rails.env.test?

# Настройки логирования
Delayed::Worker.logger = Rails.logger

# Callback для выполнения задач
class DelayedJobLogger < Delayed::Plugin
  callbacks do |lifecycle|
    lifecycle.before(:invoke_job) do |job|
      Rails.logger.info "🚀 [DelayedJob] Starting #{job.payload_object.class.name} at #{Time.current}"
    end

    lifecycle.after(:invoke_job) do |job|
      Rails.logger.info "✅ [DelayedJob] Completed #{job.payload_object.class.name}"
    end

    lifecycle.before(:error) do |worker, job, exception|
      job_class = job.payload_object.class.name rescue 'Unknown'
      error_message = exception&.message || 'Unknown error'
      Rails.logger.error "❌ [DelayedJob] Failed #{job_class}: #{error_message}"
    end
  end
end

Delayed::Worker.plugins << DelayedJobLogger 