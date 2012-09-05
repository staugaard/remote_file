module RemoteFile
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
      RemoteFile.stores.map(&:identifier) - @stored_in
    end

    def store!
      RemoteFile.store!(self)
    end

    def store_once!
      RemoteFile.store_once!(self)
    end

    def synchronize!
      RemoteFile.synchronize!(self)
    end
  end
end
