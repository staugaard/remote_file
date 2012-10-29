module RemoteFiles
  class File
    attr_reader :content, :content_type, :identifier, :stored_in, :configuration

    def initialize(identifier, options = {})
      @identifier    = identifier
      @stored_in     = options[:stored_in] || []
      @content       = options.delete(:content)
      @content_type  = options[:content_type]
      @configuration = RemoteFiles::CONFIGURATIONS[options[:configuration] || :default]
      @options       = options
    end

    def self.from_url(url)
      RemoteFiles.default_configuration.file_from_url(url)
    end

    def options
      @options.merge(
        :identifier    => identifier,
        :stored_in     => stored_in,
        :content_type  => content_type,
        :configuration => configuration.name
      )
    end

    def stored?
      !@stored_in.empty?
    end

    def stored_everywhere?
      missing_stores.empty?
    end

    def missing_stores
      configuration.stores.map(&:identifier) - @stored_in
    end

    def url(store_identifier = nil)
      store = store_identifier ? configuration.lookup_store(store_identifier) : configuration.primary_store
      return nil unless store
      store.url(identifier)
    end

    def current_url
      prioritized_stores = configuration.stores.map(&:identifier) & @stored_in

      return nil if prioritized_stores.empty?

      url(prioritized_stores[0])
    end

    def store!
      configuration.store!(self)
    end

    def store_once!
      configuration.store_once!(self)
    end

    def synchronize!
      configuration.synchronize!(self)
    end

    def delete!
      configuration.delete!(self)
    end

    def delete
      begin
        delete!
        true
      rescue RemoteFiles::Error => e
        false
      end
    end

    def delete_now!
      configuration.delete_now!(self)
    end
  end
end
