module RemoteFiles
  autoload :AbstractStore, 'remote_files/abstract_store'
  autoload :Configuration, 'remote_files/configuration'
  autoload :File, 'remote_files/file'
  autoload :FileStore, 'remote_files/file_store'
  autoload :FogStore, 'remote_files/fog_store'
  autoload :MemoryStore, 'remote_files/memory_store'
  autoload :MockStore, 'remote_files/mock_store'
  autoload :ResqueJob, 'remote_files/resque_job'
  autoload :VERSION, 'remote_files/version'

  class Error < StandardError; end
  class NotFoundError < Error; end

  CONFIGURATIONS = Hash.new do |configs, name|
    name = name.to_sym
    configs[name] = Configuration.new(name)
  end

  def self.default_configuration
    CONFIGURATIONS[:default]
  end

  def self.configure(name, hash = {})
    if name.is_a?(Hash)
      hash = name
      name = :default
    end

    CONFIGURATIONS[name.to_sym].from_hash(hash)
  end

  def self.logger=(logger)
    @logger = logger
  end

  def self.logger
    return @logger if defined?(@logger)

    @logger ||= defined?(Rails) ? Rails.logger : nil
  end

  def self.add_store(store_identifier, options = {}, &block)
    default_configuration.add_store(store_identifier, options, &block)
  end

  def self.stores
    default_configuration.stores
  end

  def self.lookup_store(store_identifier)
    default_configuration.lookup_store(store_identifier)
  end

  def self.primary_store
    default_configuration.primary_store
  end

  def self.synchronize_stores(file = nil, &block)
    if file
      if @synchronize_stores
        @synchronize_stores.call(file)
      else
        file.synchronize!
      end
    elsif block_given?
      @synchronize_stores = block
    else
      raise "invalid call to RemoteFiles.synchronize_stores"
    end
  end

  def self.delete_file(file = nil, &block)
    if file
      if @delete_file
        @delete_file.call(file)
      else
        file.delete_now!
      end
    elsif block_given?
      @delete_file = block
    else
      raise "invalid call to RemoteFiles.delete_file"
    end
  end
end
