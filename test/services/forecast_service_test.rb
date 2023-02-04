# frozen_string_literal: true

require 'test_helper'

class ForecastServiceTest < ActiveSupport::TestCase
  test 'get with not found lat long' do
    VCR.use_cassette 'forecast_not_found' do
      assert_raises ForecastService::NotFound do
        ForecastService.new.get([1, 2])
      end
    end
  end

  test 'get with valid lat long' do
    VCR.use_cassette 'forecast_found' do
      forecast = ForecastService.new.get([40.7527, -73.9772])

      assert_equal({
        relative_location: 'Hoboken, NJ',
        cwa: 'OKX',
        time: Time.new(2023, 2, 4, 14, 32, 23),
        tz: 'America/New_York',
        temperature: 14,
        temperature_unit: 'F',
        periods: [{
          name: 'Today',
          temperature: 25,
          temperature_unit: 'F',
          detailed_forecast: 'Sunny, with a high near 25. Wind chill values as low as -5. West wind 8 to 14 mph.'
        }, {
          name: 'Tonight',
          temperature: 25,
          temperature_unit: 'F',
          detailed_forecast: 'Partly cloudy. Low around 25, with temperatures rising to around 30 overnight. Wind chill values as low as 13. Southwest wind 12 to 16 mph.'
        }, {
          name: 'Sunday',
          temperature: 46,
          temperature_unit: 'F',
          detailed_forecast: 'Partly sunny, with a high near 46. Wind chill values as low as 19. Southwest wind around 17 mph, with gusts as high as 28 mph.'
        }, {
          name: 'Sunday Night',
          temperature: 36,
          temperature_unit: 'F',
          detailed_forecast: 'Mostly cloudy, with a low around 36. Southwest wind 8 to 15 mph.'
        }, {
          name: 'Monday',
          temperature: 49,
          temperature_unit: 'F',
          detailed_forecast: 'Mostly sunny. High near 49, with temperatures falling to around 45 in the afternoon. Northwest wind 7 to 13 mph.'
        }]
      }, forecast)
    end
  end

  test 'get with longer lat long rounds down' do
    VCR.use_cassette 'forecast_found' do
      forecast = ForecastService.new.get([40.752701200000004, -73.97724987363358])

      assert_equal({
        relative_location: 'Hoboken, NJ',
        cwa: 'OKX',
        time: Time.new(2023, 2, 4, 14, 32, 23)
      }, forecast.slice(:relative_location, :cwa, :time))

      assert_equal 5, forecast[:periods].size
    end
  end
end
