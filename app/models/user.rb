# frozen_string_literal: true

class User < ApplicationRecord
    before_create lambda {
                  self.auth_token = SecureRandom.hex
                }

    
end
