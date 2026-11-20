require 'digest'

module CartoDB
  module Visualization
    class RedisVizjsonCache

      # This needs to be changed whenever there're changes in the code that require invalidation of old keys
      VERSION = '1'.freeze

      def initialize(redis_cache = $tables_metadata, vizjson_version = 2)
        @redis = redis_cache
        @vizjson_version = vizjson_version
      end

      def cached(visualization_id, https_flag = false, vizjson_version = @vizjson_version)
        key = key(visualization_id, https_flag, vizjson_version)
        value = redis.get(key)
        if value.present?
          JSON.parse(value, symbolize_names: true, allow_duplicate_key: true)
        else
          result = yield
          serialized = JSON.generate(result)
          redis.setex(key, 24.hours.to_i, serialized)
          result
        end
      end

      def invalidate(visualization_id)
        purge_ids([visualization_id])
      end

      def key(visualization_id, https_flag = false, vizjson_version = @vizjson_version, domain = CartoDB.session_domain)
        base = "visualization:#{visualization_id}:vizjson#{VIZJSON_VERSION_KEY[vizjson_version]}:#{VERSION}:" \
               "#{https_flag ? 'https' : 'http'}:#{domain}"
        tag = basemap_api_key_cache_tag
        tag ? "#{base}:#{tag}" : base
      end

      def purge(vizs)
        purge_ids(vizs.map(&:id))
      end

      private

      def purge_ids(ids)
        return unless ids.count > 0
        keys = VIZJSON_VERSION_KEY.keys.map { |vizjson_version|
          Cartodb.config.fetch(:vizjson_cache_domains, [CartoDB.session_domain]).map { |domain|
            ids.map { |id| [key(id, false, vizjson_version), key(id, true, vizjson_version, domain)] }.flatten
          }.flatten
        }.flatten
        redis.del keys
      end

      # Needs to know every version because of invalidation
      VIZJSON_VERSION_KEY = {
        2 => '', # VizJSON v2
        3 => '3', # VizJSON v3
        '3n' => '3n', # VizJSON v3 forcing named maps (needed for embeds, see #7093)
        '3a' => '3a' # VizJSON v3 forcing anonymoys maps (needed for editor, see #7150)
      }.freeze

      def redis
        @redis
      end

      # Vary the cache entry when the optional CARTO basemaps key changes, without putting the key in Redis.
      def basemap_api_key_cache_tag
        configured = defined?(Cartodb) ? Cartodb.get_config(:carto_basemaps_api_key).to_s : ''
        return nil if configured.empty?

        Digest::SHA256.hexdigest(configured)[0, 8]
      end

    end
  end
end
