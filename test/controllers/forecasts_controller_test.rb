# frozen_string_literal: true

require 'test_helper'

class ForecastsControllerTest < ActionDispatch::IntegrationTest
  test 'get root redirects to new' do
    get '/'

    assert_redirected_to new_forecast_path
  end

  test 'get index redirects to new' do
    get '/forecasts'

    assert_redirected_to new_forecast_path
  end

  test 'get new' do
    get new_forecast_path

    assert_response :success

    assert_select 'form[action=?]', forecasts_path do
      assert_select 'input[type="text"][name=?]', 'forecast[address]'
      assert_select 'button[type="submit"]'
    end
  end

  test 'post create with blank address' do
    post forecasts_path, params: { forecast: { address: '' } }, as: :turbo_stream

    assert_turbo_stream action: :replace, target: 'forecast-new-form', status: :unprocessable_entity
    assert_select 'form[action=?]', forecasts_path do
      assert_select 'input[type="text"][name=?]', 'forecast[address]'
      assert_select 'button[type="submit"]'
    end
  end

  test 'post create with valid address adds job' do
    address = 'Grand Central Terminal, New York, NY'
    job_id = Forecast.new(address: address).job_id

    post forecasts_path, params: {
      forecast: { address: address }
    }, as: :turbo_stream

    assert_redirected_to forecast_path(id: job_id, address: address)
    assert_equal :pending, Rails.cache.read(WebWeather.cache_key(job_id))

    assert_enqueued_with job: GeoCoderJob, args: [job_id, address]
  end

  test 'post create with valid address and refresh parameter clears cache' do
    address = 'Grand Central Terminal, New York, NY'
    forecast = Forecast.new(address: address)
    job_id = forecast.job_id

    # First create cache entry for this forecast request
    VCR.use_cassette 'forecast_controller' do
      perform_enqueued_jobs do
        forecast.process!
      end
    end

    expected_cache_key = WebWeather.cache_key('10017', WebWeather.rounded_timestamp.iso8601)

    assert_changes -> { Rails.cache.read(expected_cache_key) }, to: nil do
      post forecasts_path, params: {
        forecast: { address: address, refresh: '10017' }
      }, as: :turbo_stream
    end

    assert_redirected_to forecast_path(id: job_id, address: address)
    assert_equal :pending, Rails.cache.read(WebWeather.cache_key(job_id))

    assert_enqueued_with job: GeoCoderJob, args: [job_id, address]
  end

  test 'post create with expired forecast' do
    forecast = Forecast.new(address: 'Grand Central Terminal, New York, NY')

    reset_forecast_cache_for! '10017'

    VCR.use_cassette 'forecast_controller' do
      perform_enqueued_jobs { forecast.process! }
    end

    3.times { Rails.cache.increment WebWeather.cache_key('10017', :count) }

    travel_to 1.hour.from_now do
      VCR.use_cassette 'forecast_controller' do
        perform_enqueued_jobs do
          post forecasts_path, params: {
            forecast: { address: forecast.address }
          }, as: :turbo_stream
        end
      end

      follow_redirect!

      assert_response :success

      assert_select 'h2', text: /Hoboken, NJ/
      assert_select 'p', text: /from cache/, count: 0

      redis_keys = redis_client.keys('ww:test:10017:*')

      assert_includes redis_keys,
        WebWeather.cache_key('10017', WebWeather.rounded_timestamp.iso8601)

      assert_includes redis_keys,
        WebWeather.cache_key('10017', (WebWeather.rounded_timestamp - 1.hour).iso8601)
    end
  end

  test 'get show with pending forecast job' do
    forecast = Forecast.new(address: 'Grand Central Terminal, New York, NY')
    forecast.process!

    get forecast_path(id: forecast.job_id)

    assert_response :success
    assert_select 'h2', text: /Retrieving/
  end

  test 'get show with not found forecast job' do
    forecast = Forecast.new(address: 'asd')

    VCR.use_cassette 'forecast_controller_not_found' do
      perform_enqueued_jobs do
        forecast.process!

      end
    end
    get forecast_path(id: forecast.job_id)

    assert_response :success
    assert_select 'h2', text: /Could not retrieve/
    assert_select 'a[href=?]', new_forecast_path
  end

  test 'get show with completed forecast job' do
    forecast = Forecast.new(address: 'Grand Central Terminal, New York, NY')

    reset_forecast_cache_for! '10017'

    VCR.use_cassette 'forecast_controller' do
      perform_enqueued_jobs do
        forecast.process!
      end
    end

    get forecast_path(id: forecast.job_id)

    assert_response :success

    assert_select 'h2', text: /Hoboken, NJ/
    assert_select 'h2 > a[href=?]', 'https://www.weather.gov/OKX/', text: /OKX/
    assert_select 'h3', text: /Currently\s+14 F/
    assert_select 'time[datetime]', text: '2/4 at 9:32 AM'
    assert_select 'div.grid > div', count: 5

    assert_select 'p', text: /from cache/, count: 0
  end

  test 'get show with completed forecast job increments counter cache' do
    forecast = Forecast.new(address: 'Grand Central Terminal, New York, NY')

    reset_forecast_cache_for! '10017'

    VCR.use_cassette 'forecast_controller' do
      perform_enqueued_jobs do
        forecast.process!
      end
    end

    get forecast_path(id: forecast.job_id)

    assert_response :success

    assert_select 'h2', text: /Hoboken, NJ/
    assert_select 'h2 > a[href=?]', 'https://www.weather.gov/OKX/', text: /OKX/
    assert_select 'h3', text: /Currently\s+14 F/
    assert_select 'time[datetime]', text: '2/4 at 9:32 AM'
    assert_select 'div.grid > div', count: 5

    assert_select 'p', text: /from cache/, count: 0

    get forecast_path(id: forecast.job_id)

    assert_response :success

    assert_select 'h2', text: /Hoboken, NJ/
    assert_select 'h2 > a[href=?]', 'https://www.weather.gov/OKX/', text: /OKX/
    assert_select 'h3', text: /Currently\s+14 F/
    assert_select 'time[datetime]', text: '2/4 at 9:32 AM'
    assert_select 'div.grid > div', count: 5

    assert_select 'p', text: /Served 2 times from cache/
  end

  test 'get show with unknown forecast job' do
    get forecast_path(id: '12345')

    assert_response :success

    assert_select 'h2', text: /forecast has expired/
    assert_select 'a[href=?]', new_forecast_path
  end
end
