require_relative 'boot_ruby_compat'

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

begin
  require 'bundler/setup'
rescue Bundler::GemNotFound => e
  warn e.message
  warn "Try running `bundle install`."
  exit 1
end
