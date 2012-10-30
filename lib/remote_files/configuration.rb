require 'remote_files/fog_store'

module RemoteFiles
  class Configuration
    attr_reader :name

    def initialize(name, config = {})
      @name       = name
      @stores     = []
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

      self
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

    def configured?
      !@stores.empty?
    end

    def stores
      raise "You need to configure add stores to the #{name} RemoteFiles configuration" unless configured?
      @stores
    end

    def lookup_store(store_identifier)
      @stores_map[store_identifier]
    end

    def primary_store
      stores.first
    end

    def store_once!(file)
      return file.stored_in.first if file.stored?

      exception = nil

      stores.each do |store|
        begin
          stored = store.store!(file)
          file.stored_in << store.identifier
          break
        rescue ::RemoteFiles::Error => e
          exception = e
        end
      end

      raise exception unless file.stored?

      file.stored_in.first
    end

    def store!(file)
      store_once!(file) unless file.stored?

      RemoteFiles.synchronize_stores(file) unless file.stored_everywhere?

      true
    end

    def delete!(file)
      RemoteFiles.delete_file(file)
    end

    def delete_now!(file)
      file.stored_in.each do |store_identifier|
        store = lookup_store(store_identifier)
        store.delete!(file.identifier)
      end
    end

    def synchronize!(file)
      file.missing_stores.each do |store_identifier|
        store = lookup_store(store_identifier)
        store.store!(file)
        file.stored_in << store.identifier
      end
    end

    def file_from_url(url, options = {})
      stores.each do |store|
        file = store.file_from_url(url, options.merge(:configuration => name))
        return file if file
      end
    end
  end
end
