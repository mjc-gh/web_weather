# frozen_string_literal: true

class Forecast
  KEY = Rails.application.key_generator.generate_key('lookup')

  include ActiveModel::API

  validates :address, presence: true

  attr_accessor :address, :refresh

  def job_id
    @job_id ||= job_id_from_address
  end

  def process!
    clear_cache! if refresh.present?

    # Add the new job to our key value store. It is pending currently and has a TTL of 30 minutes
    Rails.cache.write cache_key(job_id), :pending, expires_in: cache_ttl

    # Now try geo-code the address; this job will queue the ForecastJob
    GeoCoderJob.perform_later job_id, address
  end

  private

  delegate :cache_key, :cache_ttl, to: 'WebWeather'

  def clear_cache!
    Rails.cache.delete cache_key(refresh)
    Rails.cache.delete cache_key(refresh, :count)
  end

  # Deterministic async job IDs from address
  def job_id_from_address
    OpenSSL::HMAC.hexdigest('MD5', KEY, address.downcase.strip)
  end
end
