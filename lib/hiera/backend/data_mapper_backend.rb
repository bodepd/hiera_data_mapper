require 'hiera/backend/yaml_backend'
class Hiera
  module Backend
    class Data_mapper_backend < Yaml_backend

      def initialize(cache=nil)
        require 'yaml'
        Hiera.debug("Hiera data_mapper backend starting")

        @cache ||= Filecache.new
        # create an instance of a yaml backend that we will
        # be using to lookup the actual data values
        @yaml_backend = Yaml_backend.new
      end

      def lookup(key, scope, order_override, resolution_type)

        answer = nil

        Backend.datasources(scope, order_override) do |source|

          yamlfile = Backend.datafile(:data_mapper, scope, source, "yaml") || next
          yamlfile = File.expand_path(yamlfile)
          Hiera.debug("Looking for datamappings in #{yamlfile}")

          next unless File.exist?(yamlfile)

          data = @cache.read(yamlfile, Hash, {}) do |data|
            raw_data = YAML.load(data)
            data_mapping_hiera_style = {}
            abort('Expected data to be a hash, not ') unless raw_data.is_a?(Hash)
            raw_data.each do |k,v|
              abort('key must be a string or array') unless (v.is_a?(String) or v.is_a?(Array))
              Array(v).each do |e|
                abort("Data #{e} maps to multiple hiera keys") if data_mapping_hiera_style[e]
                data_mapping_hiera_style[e] = k
              end
            end
            data_mapping_hiera_style
          end

          next if data.empty?
          next unless data.include?(key)

          Hiera.debug("Found #{key} in #{source}")

          answer = Backend.parse_answer(data[key], scope)

        end
        Hiera.debug("key #{key} will be looked up as hiera key #{answer}")

        @yaml_backend.lookup(answer, scope, order_override, resolution_type)

      end

    end

  end
end
