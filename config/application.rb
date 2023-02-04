require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module WebWeather
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Perform jobs in a seperate thread queue
    config.active_job.queue_adapter = :async

    # Use redis with rails cache
    config.cache_store = :redis_cache_store, {
      url: ENV.fetch('REDIS_URL', 'redis://127.0.0.1:6379'), pool_size: 5, pool_timeout: 1
    }

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end

  def self.cache_key(*args)
    "ww:#{Rails.env}:#{args * ':'}"
  end

  def self.cache_ttl
    @cache_ttl = Rails.env.test? ? 30.seconds : 30.minutes
  end
end
