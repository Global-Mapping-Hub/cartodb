source 'https://rubygems.org'

ruby '4.0.10'

gem 'rails', '8.1.4.1'

# Promoted out of the default set in Ruby 4.0. Bundler will not load them
# unless they are declared here.
gem 'logger'
gem 'ostruct'
gem 'mutex_m'
gem 'drb'
gem 'base64'
gem 'bigdecimal'
gem 'benchmark'
gem 'pstore'
gem 'csv'
gem 'observer'
gem 'nkf'
gem 'webrick', '~> 1.8'
# Ruby 4 ships only cgi/escape. 0.3.7 still provides CGI.parse and CGI::Cookie.
gem 'cgi', '0.3.7'

gem 'rake', '~> 13.2'
gem 'sprockets', '~> 4.2'
gem 'sprockets-rails', '~> 3.5'

# PostgreSQL
gem 'pg', '~> 1.5'
gem 'sequel', '~> 5.80'
gem 'sequel-rails', '~> 1.2.0'
gem 'sequel_pg', '~> 1.17', require: 'sequel'

gem 'protected_attributes_continued'
gem 'responders', '~> 3.1'

gem 'rails_warden', '0.6.0'
gem 'ruby-saml', '1.7.0'
gem 'oauth', '0.4.7'
gem 'oauth-plugin', git: 'https://github.com/CartoDB/oauth-plugin.git', branch: 'cartodb'

# Redis
gem 'redis', '~> 4.8'

gem 'nokogiri', '~> 1.18'
gem 'statsd-client', '0.0.7', require: 'statsd'
gem 'aws-sdk-acmpca', '~> 1'
gem 'aws-sdk-s3', '~> 1'
gem 'ruby-prof', '~> 2.0'
gem 'request_store', '~> 1.4'
gem 'addressable', '~> 2.8', require: 'addressable/uri'

gem 'ejs', '~> 1.1.1'
gem 'execjs', '~> 2.8'

gem 'net-ldap', '~> 0.19'
gem 'json-schema', '~> 2.8'
gem 'mime-types', '~> 3.4'

group :production, :staging do
  gem 'unicorn', '~> 6.1'
  gem 'unicorn-worker-killer'
  gem 'raindrops', '~> 0.20'
end

group :assets do
  gem 'compass', '1.0.3'
end

gem 'cartodb-common', path: 'vendor/cartodb-common'
gem 'roo', '~> 2.10'
gem 'state_machines-activerecord', '~> 0.9.0'
gem 'typhoeus', '~> 1.4'
gem 'charlock_holmes', '~> 0.7.9'
gem 'dbf', '~> 4.0'
gem 'google-api-client', '0.53.0'
gem 'dropbox_api', '~> 0.1.18'
gem 'gibbon', '~> 3.4'
gem 'instagram-continued-continued'
gem 'google-cloud-pubsub', '1.2.0'
gem 'virtus', '~> 2.0'
gem 'email_address', '~> 0.1.11'
gem 'redcarpet', '~> 3.6'
gem 'rollbar', '~> 3.4'
gem 'resque', '~> 1.27'
gem 'resque-metrics', '0.1.1'
gem 'net-telnet'
gem 'rubyzip', '>= 2.0.0'
gem 'coverband', '~> 5.2.0'
gem 'test-unit'

# Multifactor Authentication
gem 'rotp', '~> 3.3', '>= 3.3.1'
gem 'rqrcode', '~> 0.10.1'

gem 'sys_cmd', '>= 1.1.3'

gem 'google-cloud-bigquery-storage-v1', '~> 0.2.3'
gem 'avro', '~> 1.10.0'

group :test do
  gem 'simplecov', '~> 0.22.0', require: false
  gem 'simplecov-json'
  gem 'simplecov-rcov'
  gem 'db-query-matchers', '~> 0.12'
  gem 'rack-test', '~> 2.1', require: 'rack/test'
  gem 'factory_bot', '6.5.0'
  gem 'factory_bot_rails', '6.4.4'
  gem 'selenium-webdriver', '~> 4.10'
  gem 'capybara', '~> 3.40'
  gem 'delorean'
  gem 'mocha', '~> 2.1'
  gem 'ci_reporter', '1.8.4'
  gem 'poltergeist', '1.18.1'
  gem 'activerecord-nulldb-adapter', '~> 1.0'
  gem 'fake_net_ldap', git: 'https://github.com/kuldeepaggarwal/fake_net_ldap.git', branch: 'fix-responder'
  gem 'mock_redis', '~> 0.34.0'
end

gem 'rbtrace', '~> 0.5'
group :test, :development do
  gem 'gc_tracer', '1.5.1'
  gem 'memory_profiler'
end

group :development, :test do
  gem 'byebug'
  gem 'pry-byebug', '~> 3.10'
  gem 'rack', '~> 3.1'
  gem 'rb-readline'
  gem 'rspec-rails', '~> 8.0'
  gem 'rubocop', '~> 1.69', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
  gem 'thin', require: false
end

gem 'analytics-ruby', '~> 2.2', require: 'segment/analytics'

require File.dirname(__FILE__) + '/lib/carto/carto_gears_support'

Carto::CartoGearsSupport.new.gears.each do |gear|
  gear.gemspec.runtime_dependencies.each do |dependency|
    # Declared above with the same requirements. Bundler 4 rejects listing them twice.
    next if %w[rails pg sprockets].include?(dependency.name)

    gem dependency.name, *dependency.requirements_list
  end
end
