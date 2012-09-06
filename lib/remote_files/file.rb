module RemoteFiles
  class File
    attr_reader :content, :content_type, :identifier, :stored_in

    def initialize(identifier, options = {})
      @identifier   = identifier
      @stored_in    = options[:stored_in] || []
      @content      = options[:content]
      @content_type = options[:content_type]
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

    def url
      
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
  end
end
