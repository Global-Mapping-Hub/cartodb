require 'oauth'

module OAuth
  module RequestProxy
    # Rails passes ActionDispatch::Request. The oauth gem only registers Rack::Request.
    class ActionDispatchRequest < RackRequest
      proxies ActionDispatch::Request
    end
  end
end

module Carto
  class DomainPatcherRequestProxy < OAuth::RequestProxy::RackRequest

    def uri
      super.sub('carto.com', 'cartodb.com')
    end

  end
end
