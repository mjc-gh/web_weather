# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

VCR.configure do |config|
  vcr_mode = ENV['VCR_MODE'] =~ /rec/i ? :all : :once

  config.cassette_library_dir = 'test/vcr_cassettes'
  config.default_cassette_options = {
    record: vcr_mode,
    match_requests_on: %i[method uri body],
    serialize_with: :compressed
  }

  config.ignore_localhost = true
  config.hook_into :webmock
end

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...

  def redis_client
    @redis_client ||= Redis.new
  end

  def reset_forecast_cache_for!(zip)
    redis_client.del WebWeather.cache_key(zip, WebWeather.rounded_timestamp.iso8601)
    redis_client.del WebWeather.cache_key(zip, :count)
  end
end

Minitest.after_run do
  redis = Redis.new
  redis.keys(WebWeather.cache_key '*').each do |key|
    redis.del key
  end
end
