# frozen_string_literal: true
ruby '3.3.0'
source 'https://rubygems.org'

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem 'rails', '~> 7.1.3.4'

# Use sqlite3 as the database for Active Record
gem  "pg"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
gem 'telegram-bot-ruby'
gem 'rack-cors', :require => 'rack/cors'


gem 'rails_12factor'

gem 'tzinfo-data'

gem 'active_model_serializers'

gem 'rest-client'
gem 'ffi', '~> 1.9', '>= 1.9.10'
gem 'russian'

gem 'httparty'

gem 'delayed_job_active_record'
gem 'daemons'
gem 'dotenv-rails'
gem 'faker'
gem 'roo'

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
# gem "jbuilder"

# Action Cable настроен для работы с PostgreSQL
# Redis не используется - см. config/cable.yml

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem


# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
# gem "rack-cors"



group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri ]
end

group :development do
  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end
gem "dockerfile-rails", ">= 1.6", :group => :development
