# frozen_string_literal: true

class ForecastJob < ApplicationJob
  queue_as :default

  def self.service
    @service ||= ForecastService.new
  end

  # Forecasts are cached by zip code value returned from the Geocoder
  def perform(job_id, location)
    fetch_forecast(location).tap do
      Rails.cache.write cache_key(job_id), location[:zip], expires_in: cache_ttl
    end
  rescue
    Rails.cache.write cache_key(job_id), :not_found, expires_in: cache_ttl
  end

  private

  delegate :cache_key, :cache_ttl, :rounded_timestamp, to: 'WebWeather'

  def fetch_forecast(location)
    Rails.cache.fetch cache_key(location[:zip], rounded_timestamp.iso8601), expires_in: cache_ttl do
      Rails.cache.delete cache_key(location[:zip], :count)

      self.class.service.get(location[:lat_long])
    end
  end
end
