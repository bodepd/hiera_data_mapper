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
          next unless File.exist?(yamlfile)
          Hiera.debug("Looking for datamappings in #{yamlfile}")

          data = @cache.read(yamlfile, Hash, {}) do |data|
            # this is where the magic happens, we convert the mappings
            # file into something key'ed off the data hiera will be looking up
            raw_data = YAML.load(data)
            data_mapping_hiera_style = {}
            raise(Exception, "Expected data to be a hash, not #{raw_data.class}") unless raw_data.is_a?(Hash)
            raw_data.each do |k,v|
              raise(Exception, 'key must be a string or array') unless (v.is_a?(String) or v.is_a?(Array))
              Array(v).each do |e|
                raise(Exception, "Data #{e} maps to multiple hiera keys") if data_mapping_hiera_style[e]
                data_mapping_hiera_style[e] = k
              end
            end
            data_mapping_hiera_style
          end

          next if data.empty?
          next unless data.include?(key)

          Hiera.debug("Found #{key} in #{source}")

          # I am not sure if I need to perform variable based interpolation on keys
          #answer = Backend.parse_answer(data[key], scope)
          answer = data[key]

        end
        Hiera.debug("key #{key} will be looked up as hiera key #{answer}") if answer

        if answer =~ /%\{([^\}]*)\}/
          result = ''
          answer.gsub(/%\{([^\}]*)\}/) do
            name = $1
            @yaml_backend.lookup(
              name,
              scope,
              order_override,
              resolution_type
            ) 
          end 
        else
    	  @yaml_backend.lookup(
    	    (answer || key),
    	    scope,
    	    order_override,
    	    resolution_type
    	  )
        end
      end


      #
      #
      #
      def process_keys(data)
        

      end

    end

  end
end
