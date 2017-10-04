require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Gustibot
  class Application < Rails::Application
    # Include the authenticity token in remote forms.
    config.action_view.embed_authenticity_token_in_remote_forms = ture 

    # Loads modules in lib
    config.autoload_paths << "#{Rails.root}/lib"
  end
end
