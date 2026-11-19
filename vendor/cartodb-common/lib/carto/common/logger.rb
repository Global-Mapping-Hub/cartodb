require 'json'
require 'logger'

module Carto
  module Common
    class Logger < ::Logger
      def initialize(logdev, shift_age = 0, shift_size = 1_048_576)
        super
        self.formatter = Formatter.new
      end

      def self.install
        return unless defined?(Rails) && Rails.logger.respond_to?(:formatter=)

        Rails.logger.formatter = Formatter.new
      end

      class Formatter < ::Logger::Formatter
        def call(severity, time, _progname, message)
          payload = message.is_a?(Hash) ? message.dup : { message: message.to_s }
          payload = { level: severity, timestamp: time.utc.iso8601(3) }.merge(payload)
          "#{JSON.generate(payload)}\n"
        end
      end
    end
  end
end
