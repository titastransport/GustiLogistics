require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Gustibot
  class Application < Rails::Application
    # Loads modules in lib
    config.autoload_paths << "#{Rails.root}/lib"
  end
end
