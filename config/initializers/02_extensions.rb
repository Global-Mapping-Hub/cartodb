# Disable XML parameter parsing when the framework still exposes it.
# Rails 5+ dropped the YAML/XML parsers that this line used to remove.
if defined?(ActionDispatch::ParamsParser) &&
   ActionDispatch::ParamsParser.const_defined?(:DEFAULT_PARSERS, false)
  ActionDispatch::ParamsParser::DEFAULT_PARSERS.delete(Mime::XML)
elsif ActionDispatch::Request.respond_to?(:parameter_parsers)
  ActionDispatch::Request.parameter_parsers.delete(Mime[:xml]) if defined?(Mime)
end

# Adds an extension method previously found in a Vizzuality fork of rails-sequel
module SequelRails
  def self.connection
    @db ||= ::Sequel.synchronize { ::Sequel::DATABASES.first }
  end
end

# Allow booting before db:migrate. Sequel 5 otherwise queries each model table
# while the class is loaded and raises if the relation is missing.
if defined?(Sequel::Model)
  # Sequel 5 moved mass-assignment column restrictions into this plugin.
  Sequel::Model.plugin :whitelist_security
  Sequel::Model.require_valid_table = false if Sequel::Model.respond_to?(:require_valid_table=)
end
