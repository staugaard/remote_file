module RemoteFile
  class MockStore < AbstractStore
    def data
      @data ||= {}
    end

    def store!(file)
      data[file.identifier] = { :content => file.content, :content_type => file.content_type}
    end

    def retrieve!(identifier)
      raise NotFoundError, "#{identifier} not found in #{self.identifier} store" unless data.has_key?(identifier)

      File.new(identifier,
        :content      => data[identifier][:content],
        :content_type => data[identifier][:content_type],
        :stored_in    => [self.identifier]
      )
    end
  end
end
