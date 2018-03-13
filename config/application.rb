require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Kairos
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.time_zone = 'Mexico City'

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '*', 
          :headers => :any, 
          :expose  => ['access-token', 'expiry', 'token-type', 'uid', 'client'],
          :methods => [:get, :post, :options, :put, :delete]
      end
    end

    config.generators do |g|
      g.test_framework  :rspec
    end
  end
end
