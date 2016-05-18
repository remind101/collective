source 'https://rubygems.org'

# Specify your gem's dependencies in collective.gemspec
gemspec

group :development do
  gem 'dalli'
  gem 'sidekiq'
  gem 'mongoid',       '~> 3.0'
  gem 'pg'
end

group :development, :test do
  gem 'rspec',         '~> 3.4.0'
  gem 'dotenv',        '~> 2.1.1'
  gem 'faker'
  gem 'activesupport'
end

group :test do
  gem 'webmock'
end
