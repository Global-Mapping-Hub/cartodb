# Ruby 4 removed several 2.x/3.x APIs this codebase and its older gems still call.
# Loaded before Bundler so native and legacy gems see the shims.

require 'uri'

class << File
  alias_method :exists?, :exist? unless method_defined?(:exists?)
end

class << Dir
  alias_method :exists?, :exist? unless method_defined?(:exists?)
end

class String
  alias_method :starts_with?, :start_with? unless method_defined?(:starts_with?)
  alias_method :ends_with?, :end_with? unless method_defined?(:ends_with?)
end

unless Object.method_defined?(:taint)
  class Object
    def taint
      self
    end

    def untaint
      self
    end

    def tainted?
      false
    end

    def trust
      self
    end

    def untrust
      self
    end

    def untrusted?
      false
    end
  end
end

module URI
  class << self
    unless method_defined?(:escape)
      def escape(str, extra_unsafe = nil)
        parser = defined?(URI::RFC2396_PARSER) ? URI::RFC2396_PARSER : URI::DEFAULT_PARSER
        extra_unsafe ? parser.escape(str.to_s, extra_unsafe) : parser.escape(str.to_s)
      end
    end

    alias encode escape unless method_defined?(:encode)

    unless method_defined?(:unescape)
      def unescape(str)
        parser = defined?(URI::RFC2396_PARSER) ? URI::RFC2396_PARSER : URI::DEFAULT_PARSER
        parser.unescape(str.to_s)
      end
    end

    alias decode unescape unless method_defined?(:decode)
  end
end
