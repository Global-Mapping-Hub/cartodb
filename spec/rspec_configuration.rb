require 'rspec/core'
require 'rspec/expectations'
require 'rspec/mocks'
require 'mocha'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.syntax = [:should, :expect]
  end
  config.mock_with :mocha
end
