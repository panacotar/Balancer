source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.4.11'

gem 'rails', '~> 8.1.4'
gem 'sprockets-rails', '~> 3.5'
gem 'pg', '~> 1.6'
gem 'puma', '~> 8.0'
gem 'bootsnap', '>= 1.18', require: false
gem 'jsbundling-rails', '~> 1.3'
gem 'cssbundling-rails', '~> 1.4'

gem 'cloudinary', '~> 2.4'
gem 'money-rails', '~> 3.0'
gem 'stripe', '~> 20.0'
gem 'pg_search', '~> 2.4'
gem 'devise', '~> 5.0'
gem 'pundit', '~> 2.5'
gem 'simple_form', '~> 5.4'
gem 'jbuilder', '~> 2.14'
gem 'sentry-ruby', '~> 7.1'
gem 'sentry-rails', '~> 7.1'
gem 'redis', '~> 5.4'
gem 'faker', '~> 3.5'
gem 'rack-attack', '~> 6.7'

group :development, :test do
  gem 'dotenv-rails', '~> 3.1'
  gem 'debug', require: 'debug/prelude'
  gem 'brakeman', require: false
  gem 'bundler-audit', require: false
end

group :development do
  gem 'web-console'
  gem 'listen', '~> 3.9'
  gem 'foreman'
  gem 'rubocop', require: false
end

group :test do
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'webmock'
end

gem 'tzinfo-data', platforms: [:windows, :jruby]
