require './config/environment'

puts "RUBY #{RUBY_VERSION}"
puts "RAILS #{Rails::VERSION::STRING}"
puts "SEQUEL #{Sequel::VERSION}"
puts "PG #{PG::VERSION}"
puts "ENV #{Rails.env}"
puts "BOOT_OK"
