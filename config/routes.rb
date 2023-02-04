Rails.application.routes.draw do
  get '/', to: redirect('/forecasts/new')
  get '/forecasts', to: redirect('/forecasts/new')

  resources :forecasts, only: %i[new create show]
end
