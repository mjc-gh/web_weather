# frozen_string_literal: true

require 'test_helper'

class GeoCoderServiceTest < ActiveSupport::TestCase
  test 'get not found address' do
    VCR.use_cassette 'geo_coder_not_found' do
      assert_raises GeoCoderService::NotFound do
        GeoCoderService.new.get('New York, NY')
      end
    end
  end

  test 'get with specific enough address' do
    VCR.use_cassette 'geo_coder_found' do
      location = GeoCoderService.new.get('Grand Central Terminal, New York, NY')

      assert_equal({
        zip: '10017',
        lat_long: [40.752701200000004, -73.97724987363358]
      }, location)
    end
  end
end
