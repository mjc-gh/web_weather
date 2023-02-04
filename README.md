# WebWeather

This app uses [Weather.gov](https://www.weather.gov/) and
[Geoapify](https://www.geoapify.com/) to retrieve current temperature
and forecast data from the National Weather Service.

## How it works

The `/forecast/new` page has a form with a single address input. A user
enters a location and a new `GeoCoderJob` is enqueued. A unique,
deterministic Job ID hash is also generated based upon the user's input.
This Job ID is used as a key for a first level cache layer. It's also
used so the user can track the state of their request on the backend.
Using a hash for caching based upon user input means user's do not
control the length of the cache keys.

If the `GeoCoderJob` finds a matching location with a zip code,
a `ForecastJob` is then enqueued with for the Job ID and returned
latitude and longtitude. If no match is found the Job ID in cache is set
to `:not_found` and error is shown to the user. This job uses the
`ForecastJob` to make a couple queries to Weather.gov to get the all
data needed to display the current temperature as well as a 3 day
forecast.

Both the `GeoCoderJob` and `ForecastJob` utilize the cache as well. The
`GeoCoderJob` uses a key based upon the Job ID. The `ForecastJob` uses a
key cache based upon the zip code returned by the geocoding process,
thus ensuring requests for the same zip code avoid querying the
`ForecastService` for a 30 minute period.

### `ForecastService`

This service makes 3 API calls to Weather.gov. The first to API request
translates a latitude and longtitude into the the geographically closest
data feed to use for the publicly available National Weather Service
forecasts. From the response of this request, this service extracts 2
forecast URLs, one for a hourly forecast to get the current temperature
and for a long term forecast.

Please refer to the "How do I get a forecast for a location from the
API?" section of the [Weather.gov docs](https://weather-gov.github.io/api/general-faqs)

## Running the app

Redis is required to run the app. A `docker-compose.yml` file has been
included for convenience:

```
docker-compose -f docker-compose.yml up -d
```

Next the you can either start the Rails server or run tests:

```
rails s -p 3000
rails test
```
