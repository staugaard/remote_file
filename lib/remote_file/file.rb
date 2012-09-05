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
      unless stored?
        RemoteFile.stores.each do |store|
          begin
            store.store!(self)
            @stored_in << store.identifier
            break
          rescue ::RemoteFile::Error => e
          end
        end
      end

      raise $! unless stored?

      RemoteFile.synchronize_stores(file) unless stored_everywhere?

      true
    end

    def synchronize!
      missing_stores.each do |store|
        store.store!(self)
        @stored_in << store.identifier
      end
    end
  end
end
