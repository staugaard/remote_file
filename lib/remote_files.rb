require 'remote_files/version'
require 'remote_files/configuration'
require 'remote_files/file'

module RemoteFiles
  class Error < StandardError; end
  class NotFoundError < Error; end

  CONFIGURATIONS = Hash.new do |configs, name|
    name = name.to_sym
    configs[name] = Configuration.new(name)
  end

  def self.default_configuration
    CONFIGURATIONS[:default]
  end

  def self.add_store(store_identifier, options = {}, &block)
    default_configuration.add_store(store_identifier, options, &block)
  end

  def self.configure(name, hash = {})
    if name.is_a?(Hash)
      hash = name
      name = :default
    end

    CONFIGURATIONS[name].from_hash(hash)
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

  def self.store_once!(file)
    file.configuration.store_once!(file)
  end

  def self.store!(file)
    file.configuration.store!(file)
  end

  def self.delete!(file)
    file.configuration.delete!(file)
  end

  def self.synchronize!(file)
    file.configuration.synchronize!(file)
  end

  def self.synchronize_stores(file = nil, &block)
    if file
      if @synchronize_stores
        @synchronize_stores.call(file)
      else
        synchronize!(file)
      end
    elsif block_given?
      @synchronize_stores = block
    else
      raise "invalid call to RemoteFiles.synchronize_stores"
    end
  end
end
