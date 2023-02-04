# frozen_string_literal: true

require 'test_helper'

class WebWeatherTest < ActiveJob::TestCase
  test 'cache_key with 1 arg' do
    assert_equal 'ww:test:key', WebWeather.cache_key('key')
  end

  test 'cache_key with multiple args' do
    assert_equal 'ww:test:key:foo:bar', WebWeather.cache_key('key', 'foo', 'bar')
  end

  test 'cache_ttl returns a duration' do
    assert_instance_of ActiveSupport::Duration, WebWeather.cache_ttl
  end

  test 'rounded_timestamp' do
    travel_to Time.new(2023, 2, 4, 12, 12) do
      assert_equal Time.new(2023, 2, 4, 12, 0),
        WebWeather.rounded_timestamp
    end

    travel_to Time.new(2023, 2, 4, 12, 42) do
      assert_equal Time.new(2023, 2, 4, 12, 30),
        WebWeather.rounded_timestamp
    end
  end
end
