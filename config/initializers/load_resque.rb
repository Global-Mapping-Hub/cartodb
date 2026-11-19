require 'resque'
require 'resque/failure/base'
require 'resque/failure/multiple'
require 'resque/failure/redis'
require './lib/resque_failure_logger'
require_dependency 'redis_factory'

# Job files reference models. Zeitwerk is not set up until after user
# initializers, so load them once autoload paths exist.
Rails.application.config.after_initialize do
  Dir[Rails.root.join('lib/resque/*.rb')].sort.each { |file| require file }
end

Resque.redis = RedisFactory.new_connection

Resque::Failure::Multiple.classes = [Resque::Failure::Redis, ResqueFailureLogger]
Resque::Failure.backend = Resque::Failure::Multiple

## Logging

Resque.logger.formatter = Resque::VerboseFormatter.new
Resque.logger.level = Logger::DEBUG

logger_output = if Rails.env.production? || Rails.env.staging?
                  Carto::Conf.new.log_file_path('resque.log')
                else
                  logger_stdout = STDOUT.dup
                  logger_stdout.sync = Rails.env.development?
                  logger_stdout
                end

Resque.logger = Carto::Common::Logger.new(logger_output)
