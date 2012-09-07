module RemoteFiles
  class File
    attr_reader :content, :content_type, :identifier, :stored_in

    def initialize(identifier, options = {})
      @identifier   = identifier
      @stored_in    = options[:stored_in] || []
      @content      = options.delete(:content)
      @content_type = options[:content_type]
      @options      = options
    end

    def self.from_url(url)
      RemoteFiles.stores.each do |store|
        file = store.file_from_url(url)
        return file if file
      end
    end

    def options
      @options.merge(
        :identifier   => identifier,
        :stored_in    => stored_in,
        :content_type => content_type
      )
    end

    def stored?
      !@stored_in.empty?
    end

    def stored_everywhere?
      missing_stores.empty?
    end

    def missing_stores
      RemoteFiles.stores.map(&:identifier) - @stored_in
    end

    def url(store_identifier = nil)
      store = store_identifier ? RemoteFiles.lookup_store(store_identifier) : RemoteFiles.primary_store
      return nil unless store
      store.url(identifier)
    end

    def current_url
      prioritized_stores = RemoteFiles.stores.map(&:identifier) & @stored_in

      return nil if prioritized_stores.empty?

      url(prioritized_stores[0])
    end

    def store!
      RemoteFiles.store!(self)
    end

    def store_once!
      RemoteFiles.store_once!(self)
    end

    def synchronize!
      RemoteFiles.synchronize!(self)
    end

    def delete!
      RemoteFiles.delete!(self)
    end

    def delete
      begin
        delete!
        true
      rescue RemoteFiles::Error => e
        false
      end
    end
  end
end
