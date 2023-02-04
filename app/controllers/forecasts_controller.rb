# frozen_string_literal: true

class ForecastsController < ApplicationController
  def new
    @forecast = Forecast.new

    render :new
  end

  def create
    @forecast = Forecast.new(forecast_params)

    if @forecast.valid?
      @forecast.process!

      redirect_to forecast_url(id: @forecast.job_id, address: @forecast.address)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @job_id = params[:id]
    @job_status = Rails.cache.read(cache_key(@job_id))

    unless @job_status == :pending
      @forecast = Rails.cache.read(cache_key(@job_status, rounded_timestamp.iso8601))
      @forecast_count = Rails.cache.increment(cache_key(@job_status, :count), expires_in: cache_ttl) if @forecast
    end

    render :show
  end

  private

  delegate :cache_key, :cache_ttl, :rounded_timestamp, to: 'WebWeather'

  def forecast_params
    params.require(:forecast).permit(:address, :refresh)
  end
end
