# frozen_string_literal: true

require 'test_helper'

class ForecastJobTest < ActiveJob::TestCase
  setup do
    @forecast = Forecast.new(address: 'Grand Central Terminal, New York, NY')

    Rails.cache.delete WebWeather.cache_key(@forecast.job_id)
  end

  test 'perform with not found lat long' do
    key = WebWeather.cache_key('test_job_id')

    redis_client.del key # reset cache

    VCR.use_cassette 'forecast_not_found' do
      ForecastJob.perform_now 'test_job_id', [1, 2]
    end

    assert_equal :not_found, Rails.cache.read(key)
  end

  test 'perform sets forecast by job id to geocoded zip code' do
    cache_key = WebWeather.cache_key(@forecast.job_id)

    assert_changes -> { Rails.cache.read cache_key }, to: '10017' do
      VCR.use_cassette 'forecast_found' do
        ForecastJob.perform_now(@forecast.job_id, {
          zip: '10017', lat_long: [40.752701200000004, -73.97724987363358]
        })
      end
    end
  end

  test 'perform sets forecast in cache' do
    cache_key = WebWeather.cache_key(@forecast.job_id, :forecast)

    VCR.use_cassette 'forecast_found' do
      ForecastJob.perform_now(@forecast.job_id, {
        zip: '10017', lat_long: [40.752701200000004, -73.97724987363358]
      })
    end

    assert_instance_of Hash, Rails.cache.read(WebWeather.cache_key('10017'))
  end
end
