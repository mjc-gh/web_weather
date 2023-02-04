source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.1.2'

gem 'bootsnap', '~> 1.16'
gem 'connection_pool'
gem 'faraday'
gem 'hiredis'
gem 'rails', '~> 7.0.4', '>= 7.0.4.2'
gem 'redis'
gem 'turbo-rails'
gem 'shakapacker', '= 6.2'
gem 'sprockets-rails', '~> 3.4', '>= 3.4.2'
gem 'sqlite3', '~> 1.4'
gem 'puma', '~> 5.0'

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]

  gem 'guard'
  gem 'guard-minitest'
  gem 'guard-rubocop'

  gem 'rubocop'
  gem 'rubocop-rails'

  gem 'pry'

  gem 'vcr'
  gem 'webmock'
end

group :development do
  gem 'web-console', '>= 3.3.0'
end
