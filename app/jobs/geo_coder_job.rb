# frozen_string_literal: true

class GeoCoderJob < ApplicationJob
  queue_as :default

  def self.service
    @service = GeoCoderService.new
  end

  # The job_id is just a hash of the address so we can use it for the geocoding
  # cache too
  def perform(job_id, address)
    location = Rails.cache.fetch(cache_key(job_id, :geo_coder), expires_in: cache_ttl) do
      self.class.service.get(address)
    end

    ForecastJob.perform_later job_id, location

  rescue GeoCoderService::NotFound
    Rails.cache.write cache_key(job_id), :not_found, expires_in: cache_ttl
  end

  delegate :cache_key, :cache_ttl, to: 'WebWeather'
end
