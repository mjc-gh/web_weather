# frozen_string_literal: true

require 'test_helper'

class ForecastTest < ActiveJob::TestCase
  test 'address is required' do
    forecast = Forecast.new(address: '')

    refute forecast.valid?
    assert_equal [error: :blank], forecast.errors.details[:address]
  end

  test 'job_id is determines based upon normalized address input' do
    forecast_1 = Forecast.new(address: 'Grand Central Terminal, New York, NY')
    forecast_2 = Forecast.new(address: 'grand central terminal, New York, NY')

    assert_equal forecast_1.job_id, forecast_2.job_id

    forecast_3 = Forecast.new(address: '  Grand Central Terminal, New York, NY')

    assert_equal forecast_2.job_id, forecast_3.job_id
  end

  test 'job_id is memoized' do
    forecast = Forecast.new(address: 'Grand Central Terminal, New York, NY')

    assert_same forecast.job_id, forecast.job_id
  end

  test 'process! enqueues GeoCoderJob' do
    forecast = Forecast.new(address: 'Grand Central Terminal, New York, NY')

    assert_enqueued_with job: GeoCoderJob, args: [forecast.job_id, forecast.address] do
      forecast.process!
    end
  end

  test 'process! sets job cache to pending' do
    forecast = Forecast.new(address: 'Grand Central Terminal, New York, NY')
    key = WebWeather.cache_key(forecast.job_id)

    redis_client.del key # reset cache

    assert_changes -> { Rails.cache.read key }, to: :pending do
      forecast.process!
    end
  end

  test 'process! does not clear cache without refresh' do
    forecast = Forecast.new(address: 'Grand Central Terminal, New York, NY')
    key = WebWeather.cache_key('10017')

    Rails.cache.write key, {}

    assert_no_changes -> { Rails.cache.read key } do
      forecast.process!
    end
  end

  test 'process! clears cache when refresh is set' do
    key = WebWeather.cache_key('12345')

    Rails.cache.write key, { relative_location: 'Example' }
    Rails.cache.increment WebWeather.cache_key('12345', :count)

    assert_changes -> { Rails.cache.read key }, to: nil do
      Forecast.new(address: 'Test', refresh: '12345').process!
    end
  end
end
