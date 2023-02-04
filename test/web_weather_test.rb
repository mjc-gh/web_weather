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
end
