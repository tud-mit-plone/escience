require File.expand_path('../boot', __FILE__)

require 'rails/all'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module RedmineApp
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(#{config.root}/lib)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    config.active_record.observers = :message_observer, :issue_observer, :journal_observer, :news_observer, :document_observer, :wiki_content_observer, :comment_observer

    config.active_record.store_full_sti_class = true
    config.active_record.default_timezone = :local
    I18n.enforce_available_locales = true
    I18n.available_locales = [:de, :en]

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    console do
        # this block is called only when running console,
        # so we can safely require pry here
        require "pry"
         config.console = Pry
    end

    config.action_dispatch.x_sendfile_header = "X-Accel-Redirect"

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable the asset pipeline
    config.assets.enabled = false

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    config.before_configuration do
      env_file = File.join(Rails.root, 'config', 'local_env.yml')
      YAML.load(File.open(env_file)).each do |key, value|
        ENV[key.to_s] = value
      end if File.exists?(env_file)
    end

    config.action_mailer.perform_deliveries = false

    config.session_store :cookie_store, :key => '_redmine_session', :secure => Rails.env.production?

    if File.exists?(File.join(File.dirname(__FILE__), 'additional_environment.rb'))
      instance_eval File.read(File.join(File.dirname(__FILE__), 'additional_environment.rb'))
    end
  end
end
