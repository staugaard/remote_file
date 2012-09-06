module RemoteFiles
  class AbstractStore
    attr_reader :identifier

    def initialize(identifier)
      @identifier = identifier
    end

    def store!(file)
    end

    def retrieve!(identifier)
    end
  end
end
