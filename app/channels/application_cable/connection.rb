# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      Rails.logger.info "🔌 [ApplicationCable::Connection] New connection attempt from #{request.remote_ip}"
      Rails.logger.info "🔌 [ApplicationCable::Connection] Request params: #{request.params.inspect}"
      
      self.current_user = find_verified_user
      
      Rails.logger.info "🔌 [ApplicationCable::Connection] ✅ Connection established for user #{current_user.id} (#{current_user.name})"
    end

    private

    def find_verified_user
      # Получаем user_id из параметров соединения
      user_id = request.params[:user_id]
      Rails.logger.info "🔌 [ApplicationCable::Connection] Looking for user_id: #{user_id}"
      
      if user_id && (user = User.find_by(id: user_id))
        Rails.logger.info "🔌 [ApplicationCable::Connection] Found user: #{user.id} (#{user.name})"
        user
      else
        Rails.logger.warn "🔌 [ApplicationCable::Connection] ❌ User not found or missing user_id, rejecting connection"
        reject_unauthorized_connection
      end
    end
  end
end
