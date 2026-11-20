# Legacy files under app/ do not match Zeitwerk's expected constant names.
# Requiring them during boot raises. Ignore the mismatches so explicit
# requires still work and production can start.

# Sequel 5.110 no longer treats table__column as table.column. The importer
# still uses that form, for example pg_class__oid.
require 'sequel'
Sequel.split_symbols = true
Rails.application.config.eager_load = false
Rails.application.config.after_initialize do
  Rails.application.config.eager_load_namespaces.clear
end

# Coverband 5.2 passes regular expressions to Rack::Static. Rack 3.2 calls
# String#end_with? on each URL and aborts route loading. Keep the source so
# the reporter can still be constructed.
require 'rack/static'

module CartodbDockerRackStaticUrls
  def initialize(app, options = {})
    urls = options[:urls]
    if urls&.any? { |url| !url.respond_to?(:end_with?) }
      options = options.merge(urls: urls.map { |url| url.respond_to?(:end_with?) ? url : url.source })
    end
    super
  end
end
Rack::Static.prepend(CartodbDockerRackStaticUrls)

# Rails 8 Errors#[] returns a copy, and Errors has no []=. Legacy validators assign
# and append messages with errors[:field] = [...] and errors[:field] << "...".
class CartodbDockerErrorArray < Array
  def initialize(errors, attribute, messages)
    @errors = errors
    @attribute = attribute
    super(messages)
  end

  def <<(message)
    @errors.add(@attribute, message)
    super
  end
end

module CartodbDockerErrorMessages
  def [](attribute)
    CartodbDockerErrorArray.new(self, attribute, super)
  end

  def []=(attribute, messages)
    delete(attribute)
    Array(messages).each { |message| add(attribute, message) }
  end
end
ActiveModel::Errors.prepend(CartodbDockerErrorMessages)

# Sequel 5 rejects the Sequel 4 placeholder form used throughout this app:
#   where("email = ?", email) and where(["tags && ARRAY[?]", tag])
module CartodbDockerSequelFilters
  def filter_expr(expr = nil, &block)
    if expr.is_a?(Array) && expr.first.is_a?(String) && !Sequel.condition_specifier?(expr)
      expr = Sequel.lit(*expr)
    end
    super
  end
end
Sequel::Dataset.prepend(CartodbDockerSequelFilters)

# Rails removed ActionController#env. Login and the dashboard still read env["warden"].
module CartodbDockerControllerEnv
  def env
    request.env
  end
end
ActionController::Base.prepend(CartodbDockerControllerEnv)
ActionController::Base.helper_method(:env)

# Rails 8 requires render(file:) to be an absolute path.
module CartodbDockerRenderFile
  def render(*args, **kwargs, &block)
    options = kwargs if kwargs.key?(:file)
    if !options && args.last.is_a?(Hash) && args.last.key?(:file)
      args[-1] = args.last.dup
      options = args[-1]
    end
    if options && options[:file].is_a?(String) && options[:file][0] != '/'
      options[:file] = Rails.root.join(options[:file]).to_s
    end
    super
  end
end
ActionController::Base.prepend(CartodbDockerRenderFile)

require 'digest'

# Rails 8 removed ConnectionSpecification. User database connections still build
# one and pass it to connection_handler.establish_connection(name, spec).
module ActiveRecord
  module ConnectionAdapters
    module ConnectionSpecification
      class Resolver
        def initialize(*)
        end

        def spec(config)
          hash = config.each_with_object({}) { |(key, value), normalized| normalized[key.to_s] = value }
          hash.delete('orm')
          hash.delete('logger')
          Struct.new(:config).new(hash)
        end
      end
    end
  end
end

class CartodbDockerConnectionLease
  def initialize(pool)
    @pool = pool
  end

  def connection
    @pool.lease_connection
  end
end

module CartodbDockerEstablishConnection
  def establish_connection(config, *rest, owner_name: ActiveRecord::Base, role: ActiveRecord::Base.current_role, shard: ActiveRecord::Base.current_shard, clobber: false)
    if rest.length == 1
      spec = rest.first
      hash = spec.respond_to?(:config) ? spec.config : spec
      owner = "cartodb_#{Digest::SHA256.hexdigest(hash.sort.to_s)}"
      db_config = ActiveRecord::DatabaseConfigurations::HashConfig.new(Rails.env.to_s, owner, hash)
      pool = super(db_config, owner_name: owner, role: role, shard: shard, clobber: true)
      return CartodbDockerConnectionLease.new(pool)
    end

    super(config, owner_name: owner_name, role: role, shard: shard, clobber: clobber)
  end
end
ActiveRecord::ConnectionAdapters::ConnectionHandler.prepend(CartodbDockerEstablishConnection)

# Rails removed Relation#uniq. These queries use it to mean DISTINCT and then call to_sql.
module CartodbDockerRelationUniq
  def uniq(value = true)
    distinct(value)
  end
end
ActiveRecord::Relation.prepend(CartodbDockerRelationUniq)

# Custom JSON coders use try(&:to_json), which does not call to_json, and
# load returns a raw string. Notifications are then indexed with a symbol.
module CartodbDockerJsonCoder
  def dump(value)
    return if value.nil?
    value.is_a?(String) ? value : JSON.generate(value.as_json)
  end

  def load(value)
    parsed = value
    3.times do
      break unless parsed.is_a?(String)
      parsed = JSON.parse(parsed)
    end
    super(parsed)
  rescue JSON::ParserError
    super(value)
  end
end

# Rails 8 casts a serialized hash through the text column, so the in-memory
# value becomes a JSON string and validations reject it.
module CartodbDockerSerializedCast
  def cast(value)
    casted = super
    return casted if coder.nil? || casted.nil? || casted.is_a?(Hash) || casted.is_a?(Array)

    coder.load(casted)
  rescue StandardError
    casted
  end
end
ActiveRecord::Type::Serialized.prepend(CartodbDockerSerializedCast)

module CartodbDockerNotifications
  def notifications_for_category(category)
    notes = static_notifications.notifications
    notes = JSON.parse(notes) if notes.is_a?(String)
    notes = notes.deep_symbolize_keys if notes.respond_to?(:deep_symbolize_keys)
    return {} unless notes.respond_to?(:[])

    notes[category] || notes[category.to_s] || {}
  rescue JSON::ParserError
    {}
  end
end

Rails.application.config.to_prepare do
  [Carto::CartoJsonSerializer, Carto::CartoJsonSymbolizerSerializer].each do |serializer|
    next if serializer.singleton_class.ancestors.include?(CartodbDockerJsonCoder)

    serializer.singleton_class.prepend(CartodbDockerJsonCoder)
  end
  Carto::User.prepend(CartodbDockerNotifications) unless Carto::User.ancestors.include?(CartodbDockerNotifications)

  # The dashboard API rewrites every user URL to https. This server is HTTP only.
  presenter = Carto::Api::UserPresenter
  unless presenter.ancestors.include?(CartodbDockerHttpBaseUrl)
    presenter.prepend(CartodbDockerHttpBaseUrl)
  end

  api_key = Carto::ApiKey
  api_key.prepend(CartodbDockerGrantsReader) unless api_key.ancestors.include?(CartodbDockerGrantsReader)
end

# Serialized JSON is handed to validations as a string. Read it back as data.
module CartodbDockerGrantsReader
  def grants
    value = super
    return value unless value.is_a?(String)

    parsed = JSON.parse(value)
    if parsed.is_a?(Array)
      parsed.map { |item| item.is_a?(Hash) ? item.deep_symbolize_keys : item }
    elsif parsed.is_a?(Hash)
      parsed.deep_symbolize_keys
    else
      parsed
    end
  rescue JSON::ParserError
    value
  end
end

module CartodbDockerHttpBaseUrl
  def data(options = {})
    payload = super
    if payload.is_a?(Hash) && payload[:base_url].is_a?(String) && Cartodb.config[:ssl_required] != true
      payload[:base_url] = payload[:base_url].sub(/\Ahttps:/, 'http:')
    end
    payload
  end
end

# Ruby 3 does not turn a trailing hash into keywords. Callers still pass that hash.
Rails.application.config.to_prepare do
  searcher = Carto::Api::PagedSearcher
  next if searcher.ancestors.any? { |ancestor| ancestor.instance_methods(false).include?(:cartodb_docker_paged_order) }

  searcher.prepend(Module.new do
    def page_per_page_order_params(*args, **kwargs)
      kwargs = args.pop.merge(kwargs) if args.last.is_a?(Hash)
      super
    end

    def paged_result(result:, total_count:, page:, per_page:, params:)
      params = params.to_unsafe_h if params.respond_to?(:to_unsafe_h)
      super
    end

    def cartodb_docker_paged_order
    end
  end)
end

# protected_attributes replaces init_attributes and rejects the one-argument dup call.
# ActiveModel::Dirty must still run so duplicated attributes are included in the INSERT.
module CartodbDockerInitAttributes
  def init_attributes(attributes = nil, options = {})
    if attributes.is_a?(ActiveRecord::Base)
      method(__method__).super_method.super_method.call(attributes)
    else
      super(attributes, options)
    end
  end
end
ActiveRecord::Base.prepend(CartodbDockerInitAttributes)

# Rails 8 rejects raw SQL passed to order.
module CartodbDockerOrderSql
  def order(*args)
    super(*args.map { |arg| arg.is_a?(String) ? Arel.sql(arg) : arg })
  end
end
ActiveRecord::Relation.prepend(CartodbDockerOrderSql)

# data_imports.logger collides with Active Record. Rails 8 also checks logger?.
module CartodbDockerAllowLoggerColumn
  def instance_method_already_implemented?(method_name)
    return true if %w[logger logger?].include?(method_name.to_s)
    super
  end
end
ActiveRecord::Base.singleton_class.prepend(CartodbDockerAllowLoggerColumn)

# Rails 8 parameterize is keyword-only. Callers still pass the separator positionally.
module CartodbDockerParameterize
  def parameterize(*args, **kwargs)
    kwargs[:separator] = args.shift if args.length == 1 && !kwargs.key?(:separator)
    super(*args, **kwargs)
  end
end
String.prepend(CartodbDockerParameterize)

# Ruby 4 raises when a Hash has both "data_type" and :data_type and is rendered as JSON.
module CartodbDockerJsonGenerate
  def generate(obj, opts = nil)
    options = opts.is_a?(Hash) ? opts.merge(allow_duplicate_key: true) : { allow_duplicate_key: true }
    super(cartodb_docker_json_dedupe(obj), options)
  end

  def cartodb_docker_json_dedupe(obj)
    case obj
    when Hash
      deduped = {}
      obj.each do |key, value|
        deduped[key.is_a?(Symbol) ? key.to_s : key] = cartodb_docker_json_dedupe(value)
      end
      deduped
    when Array
      obj.map { |item| cartodb_docker_json_dedupe(item) }
    else
      obj
    end
  end
end
require 'json'
JSON.singleton_class.prepend(CartodbDockerJsonGenerate)

encoder = ActiveSupport::JSON::Encoding::JSONGemCoderEncoder
encoder.send(:remove_const, :CODER)
encoder.const_set(:CODER, JSON::Coder.new(allow_duplicate_key: true) do |value, is_key|
  if is_key
    next value if Symbol === value

    next value.to_s
  end

  json_value = value.as_json
  if json_value.equal?(value)
    next JSON::Fragment.new(JSON.generate(json_value, allow_duplicate_key: true))
  end

  count = 5
  until encoder::JSON_NATIVE_TYPES.include?(json_value.class)
    raise SystemStackError if count.zero?

    json_value = json_value.as_json
    count -= 1
  end
  json_value
end)

# A browser session has no API token. Treat that signed-in user as the master key
# so the dashboard can list keys instead of crashing.
module CartodbDockerSessionApiKey
  def request_api_key
    key = super
    return key if key
    return nil unless respond_to?(:current_user, true) && current_user

    fallback = Object.new
    fallback.define_singleton_method(:master?) { true }
    fallback.define_singleton_method(:id) { nil }
    fallback
  end
end
Carto::Api::AuthApiAuthentication.prepend(CartodbDockerSessionApiKey)

loader = Rails.autoloaders.main
loader.ignore(Rails.root.join('gears/carto_gears_api/lib/carto_gears_api/version.rb'))
app_root = Rails.root.join('app')
ignored = 0

def cartodb_docker_camelize(segment)
  segment.split('_').map { |word| word.empty? ? word : word[0].upcase + word[1..] }.join
end

def cartodb_docker_defined_constants(source)
  stack = []
  defined = []
  source.each_line do |line|
    stripped = line.strip
    next if stripped.start_with?('#')

    if stripped =~ /\A(?:module|class)\s+([A-Z]\w*(?:::[A-Z]\w*)*)\b/
      stack.concat(Regexp.last_match(1).split('::'))
      defined << stack.join('::')
    elsif stripped == 'end' && !stack.empty?
      stack.pop
    end
  end
  defined
end

Dir[app_root.join('**/*.rb')].each do |file|
  relative = Pathname.new(file).relative_path_from(app_root).each_filename.to_a
  root_name = relative.shift
  next if %w[assets views javascripts].include?(root_name)

  relative.reject! { |part| part == 'concerns' }
  next if relative.empty?

  relative[-1] = relative[-1].delete_suffix('.rb')
  expected = relative.map { |part| cartodb_docker_camelize(part) }.join('::')
  next if cartodb_docker_defined_constants(File.read(file)).include?(expected)

  loader.ignore(file)
  ignored += 1
end

warn "cartodb: ignored #{ignored} app files that do not match Zeitwerk names"
