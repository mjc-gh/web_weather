# frozen_string_literal: true

class GeoCoderService
  NotFound = Class.new(StandardError)

  def initialize
    @conn = Faraday.new('https://api.geoapify.com') do |f|
      f.response :json

      f.headers['Content-Type'] = 'application/json'
      f.params[:apiKey] = Rails.application.credentials.geo_coder_api_key
    end
  end

  def get(address)
    parse_response @conn.get('/v1/geocode/search') { |req| req.params[:text] = address }
  end

  private

  def parse_response(resp)
    raise NotFound unless resp.success?

    props = resp.body['features']&.find { |feat| feat.dig('properties', 'postcode') }&.fetch('properties')
    raise NotFound unless props

    { zip: props['postcode'], lat_long: [props['lat'], props['lon']] }
  end
end
