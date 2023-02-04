# frozen_string_literal: true

require 'test_helper'

class GeoCoderJobTest < ActiveJob::TestCase
  setup do
    @forecast = Forecast.new(address: 'Grand Central Terminal, New York, NY')
  end

  test 'perform with not found location' do
    forecast = Forecast.new(address: 'New York, NY')
    key = WebWeather.cache_key(forecast.job_id)

    redis_client.del key # reset cache

    VCR.use_cassette 'geo_coder_not_found' do
      GeoCoderJob.perform_now forecast.job_id, forecast.address
    end

    assert_equal :not_found, Rails.cache.read(key)
  end

  test 'perform enqueues forecast job' do
    VCR.use_cassette 'geo_coder' do
      GeoCoderJob.perform_now @forecast.job_id, @forecast.address

      assert_enqueued_with job: ForecastJob, args: [@forecast.job_id, {
        zip: '10017', lat_long: [40.752701200000004, -73.97724987363358]
      }]
    end
  end

  test 'perform caches geo coder result' do
    VCR.use_cassette 'geo_coder_found' do
      GeoCoderJob.perform_now @forecast.job_id, @forecast.address
    end

    assert_equal({
      zip: '10017', lat_long: [40.752701200000004, -73.97724987363358]
    }, Rails.cache.read(WebWeather.cache_key(@forecast.job_id, :geo_coder)))
  end
end
