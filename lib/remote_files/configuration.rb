require 'remote_files/fog_store'

module RemoteFiles
  class Configuration
    def initialize(config = {})
      @stores = []
      @stores_map = {}
      from_hash(config)
    end

    def clear
      @stores.clear
      @stores_map.clear
    end

    def from_hash(hash)
      hash.each do |store_identifier, config|
        #symbolize_keys!
        cfg = {}
        config.each { |name, value| cfg[name.to_sym] = config[name] }
        config = cfg

        #camelize
        type = config[:type].gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase } + 'Store'

        klass = RemoteFiles.const_get(type) rescue nil
        unless klass
          require "remote_files/#{config[:type]}_store"
          klass = RemoteFiles.const_get(type)
        end

        config.delete(:type)

        add_store(store_identifier.to_sym, :class => klass, :primary => !!config.delete(:primary)) do |store|
          config.each do |name, value|
            store[name] = value
          end
        end
      end
    end


    def add_store(store_identifier, options = {}, &block)
      store = (options[:class] || FogStore).new(store_identifier)
      block.call(store) if block_given?

      if options[:primary]
        @stores.unshift(store)
      else
        @stores << store
      end

      @stores_map[store_identifier] = store
    end

    def stores
      raise "You need to configure add stores to RemoteFiles" if @stores.empty?
      @stores
    end

    def lookup_store(store_identifier)
      @stores_map[store_identifier]
    end

    def primary_store
      @stores.first
    end

  end
end
