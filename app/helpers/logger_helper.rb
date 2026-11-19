require 'active_support/concern'

module LoggerHelper

  extend ActiveSupport::Concern

  def log_debug(params = {}, **kwargs)
    rails_log(:debug, log_params(params, kwargs))
  end

  def log_info(params = {}, **kwargs)
    rails_log(:info, log_params(params, kwargs))
  end

  def log_warning(params = {}, **kwargs)
    rails_log(:warn, log_params(params, kwargs))
  end

  def log_error(params = {}, **kwargs)
    merged = log_params(params, kwargs)
    rails_log(:error, merged)
    send_exception_to_rollbar(merged)
  end

  def log_fatal(params = {}, **kwargs)
    merged = log_params(params, kwargs)
    rails_log(:fatal, merged)
    send_exception_to_rollbar(merged)
  end

  private

  def log_params(params, kwargs)
    hash = params.respond_to?(:to_h) ? params.to_h : {}
    hash.merge(kwargs)
  end

  def rails_log(level, params)
    parsed_params = {}.with_indifferent_access

    params.each do |key, value|
      if value.is_a?(Exception)
        parsed_params[:exception] = { class: value.class.name, message: value.message, backtrace_hint: value.backtrace&.take(5) }
        parsed_params[:message] = value.message if params[:message].blank?
      elsif value.is_a?(::User) || value.is_a?(::Carto::User)
        parsed_params[key] = value.username
      elsif value.is_a?(Carto::Organization)
        parsed_params[key] = value.name
      else
        parsed_params[key] = value
      end
    end

    Rails.logger.send(level, log_context.merge(parsed_params))
  end

  def send_exception_to_rollbar(params)
    exception = params[:exception]
    message = params[:message]

    if message && exception && exception.is_a?(Exception)
      Rollbar.error(exception, message)
    else
      Rollbar.error(exception || message)
    end
  end

  # Can be overriden in more specific contexts to add additional information.
  # Example: current_user and request_id in a controller
  def log_context
    {}.with_indifferent_access
  end

end
