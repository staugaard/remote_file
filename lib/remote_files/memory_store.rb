# This is good for use in tests.
# Be sure to call #clear! before each test run.

module RemoteFiles
  class MemoryStore < AbstractStore
    def data
      @data ||= {}
    end

    def clear!
      data.clear
    end

    def self.clear!
      RemoteFiles::CONFIGURATIONS.values.each do |config|
        next unless config.configured?
        config.stores.each do |store|
          store.clear! if store.is_a?(RemoteFiles::MemoryStore)
        end
      end
    end

    def store!(file)
      content = file.content.respond_to?(:read) ? file.content.read : file.content
      data[file.identifier] = { :content => content, :content_type => file.content_type, :last_update_ts => file.last_update_ts}
    end

    def retrieve!(identifier)
      raise NotFoundError, "#{identifier} not found in #{self.identifier} store" unless data.has_key?(identifier)

      File.new(identifier,
        :content      => data[identifier][:content],
        :content_type => data[identifier][:content_type],
        :last_update_ts => data[identifier][:last_update_ts],
        :stored_in    => [self]
      )
    end

    def files(prefix = '')
      @data.reject do |identifier|
        !identifier.start_with? prefix
      end.map do |identifier, data|
        File.new(identifier,
                 :content_type => data[:content_type],
                 :last_update_ts => data[:last_update_ts],
                 :stored_in => [self]
        )
      end
    end

    def directory_name
      self.identifier.to_s
    end

    def delete!(identifier)
      raise NotFoundError, "#{identifier} not found in #{self.identifier} store" unless data.has_key?(identifier)
      data.delete(identifier)
    end

    def url(identifier)
      "memory://#{self.identifier}/#{identifier}"
    end

    def url_matcher
      @url_matcher ||= /memory:\/\/#{identifier}\/(.*)/
    end
  end
end
