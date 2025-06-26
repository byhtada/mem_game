# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  # Автоматически повторять задачи при deadlock
  retry_on ActiveRecord::Deadlocked, wait: 5.seconds, attempts: 3

  # Пропускать задачи если записи больше не существуют
  discard_on ActiveJob::DeserializationError

  # Логирование для отладки (Delayed Job уже логирует через callbacks)
  before_perform do |job|
    Rails.logger.info "🎯 [#{job.class.name}] Job started with arguments: #{job.arguments.inspect}"
  end

  after_perform do |job|
    Rails.logger.info "🎯 [#{job.class.name}] Job completed successfully"
  end

  rescue_from(StandardError) do |exception|
    Rails.logger.error "💥 [#{self.class.name}] Job error: #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n")
    raise exception
  end
end
