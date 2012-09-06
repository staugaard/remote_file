module RemoteFiles
  class AbstractStore
    attr_reader :identifier

    def initialize(identifier)
      @identifier = identifier
    end

    def store!(file)
      raise "You need to implement #{self.class.name}#store!"
    end

    def retrieve!(identifier)
      raise "You need to implement #{self.class.name}#retrieve!"
    end

    def url(identifier)
      raise "You need to implement #{self.class.name}#url"
    end
  end
end
