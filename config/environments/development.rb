Multiverse::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true

  # AC: I can't see why I wouldn't want to test my caching locally
  config.action_controller.perform_caching = true
  
  # Don't preload everything
  config.eager_load = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin
  
  config.log_level = :info
  ##### Try to avoid crashing
  #config.log_level = :warn


  if Rails::VERSION::STRING >= '3.1'
  
    config.assets.enabled = true
    config.assets.version = '1.0'
    config.assets.compile = true
    
    # Do not compress assets
    config.assets.compress = false
      
    # Print deprecation notices to the Rails logger
    config.active_support.deprecation = :log

    # Expands the lines which load the assets
    config.assets.debug = true  # doubles up execution if application.js is compiled :/
    
    # Dodge precompiled assets
    #config.assets.prefix = "/dev-assets"
    
    config.serve_static_assets = true

    # Raise exception on mass assignment protection for Active Record models
    config.active_record.mass_assignment_sanitizer = :strict

    # Log the query plan for queries taking more than this (works
    # with SQLite, MySQL, and PostgreSQL)
    #config.active_record.auto_explain_threshold_in_seconds = 0.5
    ActiveRecord::Base.logger = Logger.new(STDOUT)
  end
end
