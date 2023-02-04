# frozen_string_literal: true

class ForecastService
  NotFound = Class.new(StandardError)

  def initialize
    @conn = Faraday.new('https://api.weather.gov/') do |f|
      f.response :json
      f.headers['Content-Type'] = 'application/json'
    end
  end

  def get(lat_long)
    # Round down to avoid an API redirect from api.weather.gov
    points_resp = @conn.get("/points/#{lat_long.map { |ll| ll.round(4) } * ','}")
    raise NotFound unless points_resp.success?

    forecast_resp, forecast_hourly_resp = get_forecast_responses(points_resp)
    raise NotFound unless forecast_resp.success? && forecast_hourly_resp.success?

    build_forecast_data points_resp, forecast_resp, forecast_hourly_resp
  end

  private

  def get_forecast_responses(points_resp)
    props = points_resp.body['properties']
    forecast_url = props['forecast']
    forecast_hourly_url = props['forecastHourly']

    raise NotFound unless forecast_url && forecast_hourly_url

    [@conn.get(forecast_url[23..-1]), @conn.get(forecast_hourly_url[23..-1])]
  end

  # TODO more error handling here...
  def build_forecast_data(points_resp, forecast_resp, forecast_hourly_resp)
    rel_loc = points_resp.body.dig('properties', 'relativeLocation', 'properties')

    forecast = forecast_resp.body['properties']
    forecast_hourly = forecast_hourly_resp.body.dig('properties', 'periods').first

    { relative_location: "#{rel_loc['city']}, #{rel_loc['state']}",
      cwa: points_resp.body.dig('properties', 'cwa'),
      time: Time.parse(forecast['updateTime']),
      tz: points_resp.body.dig('properties', 'timeZone'),
      temperature: forecast_hourly['temperature'],
      temperature_unit: forecast_hourly['temperatureUnit'],
      periods: extract_from_periods(forecast) }
  end

  def extract_from_periods(forecast)
    forecast['periods'][0, 5].map do |period|
      period.slice('name', 'temperature', 'temperatureUnit', 'detailedForecast').tap do |hash|
        hash.transform_keys! { |key| key.underscore.to_sym }
      end
    end
  end
end
