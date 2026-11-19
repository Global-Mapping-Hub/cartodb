module Carto
  module Common
    # Logging helpers mixed into Resque jobs. Jobs call these from class methods.
    module JobLogger
      def self.included(base)
        base.extend(self)
      end

      def log_debug(params = {}, **kwargs)
        write_log(:debug, params, kwargs)
      end

      def log_info(params = {}, **kwargs)
        write_log(:info, params, kwargs)
      end

      def log_warning(params = {}, **kwargs)
        write_log(:warn, params, kwargs)
      end

      def log_error(params = {}, **kwargs)
        write_log(:error, params, kwargs)
      end

      def log_fatal(params = {}, **kwargs)
        write_log(:fatal, params, kwargs)
      end

      private

      def write_log(level, params, kwargs)
        hash = params.respond_to?(:to_h) ? params.to_h : {}
        Rails.logger.public_send(level, hash.merge(kwargs))
      end
    end
  end
end
