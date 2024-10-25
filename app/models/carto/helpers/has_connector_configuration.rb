module Carto
  module HasConnectorConfiguration
    def connector_configuration(provider_name)
      puts '<><><><><> HasConnectorConfiguration <><><<><><>'
      puts provider_name.inspect
      provider = ConnectorProvider.find_by_name(provider_name)
      puts ConnectorProvider.inspect
      puts provider.inspect
      ConnectorConfiguration.for_user(self, provider)
    end
  end
end
