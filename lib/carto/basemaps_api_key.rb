require 'cgi'

module Carto
  # Applies the optional carto_basemaps_api_key to basemaps.cartocdn.com tile URLs.
  module BasemapsApiKey
    CARTOCDN_HOST = 'basemaps.cartocdn.com'.freeze
    URL_KEYS = %w(url urlTemplate urlTemplate2x).freeze
    UNDEFINED = Object.new

    module_function

    def api_key
      return nil unless defined?(Cartodb)

      Cartodb.get_config(:carto_basemaps_api_key).presence
    end

    def apply_to_url(url, key = UNDEFINED)
      key = api_key if key.equal?(UNDEFINED)
      return url unless url.is_a?(String) && key.present? && cartocdn_basemap_url?(url)

      escaped = CGI.escape(key.to_s)
      if url.match?(/[?&]key=/)
        url.sub(/([?&])key=[^&#]*/, "\\1key=#{escaped}")
      else
        "#{url}#{url.include?('?') ? '&' : '?'}key=#{escaped}"
      end
    end

    def apply_to_options(options, key = UNDEFINED)
      return options unless options.is_a?(Hash)

      key = api_key if key.equal?(UNDEFINED)
      return options if key.blank?

      apply_to_options!(options.deep_dup, key)
    end

    def apply_to_options!(options, key)
      return options unless options.is_a?(Hash) && key.present?

      URL_KEYS.each do |url_key|
        current = read_option(options, url_key)
        next unless current.is_a?(String)

        write_option(options, url_key, apply_to_url(current, key))
      end

      labels = read_option(options, 'labels')
      apply_to_options!(labels, key) if labels.is_a?(Hash)
      options
    end

    def apply_to_basemaps!(basemaps, key = UNDEFINED)
      key = api_key if key.equal?(UNDEFINED)
      return basemaps unless key.present? && basemaps.is_a?(Hash)

      basemaps.each_value do |group|
        next unless group.is_a?(Hash)

        group.each_value do |attrs|
          apply_to_options!(attrs, key) if attrs.is_a?(Hash)
        end
      end
      basemaps
    end

    def cartocdn_basemap_url?(url)
      url.include?(CARTOCDN_HOST)
    end

    def read_option(options, key)
      return options[key] if options.key?(key)
      return options[key.to_sym] if options.key?(key.to_sym)

      nil
    end

    def write_option(options, key, value)
      if !options.key?(key) && options.key?(key.to_sym)
        options[key.to_sym] = value
      else
        options[key] = value
      end
    end

    private_class_method :cartocdn_basemap_url?, :read_option, :write_option
  end
end
