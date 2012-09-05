require 'remote_file/version'
require 'remote_file/fog_store'
require 'remote_file/file'

module RemoteFile
  class Error < StandardError; end
  class NotFoundError < Error; end

  STORES_MAP = {}
  STORES = []

  def self.add_store(store_identifier, options = {}, &block)
    store = FogStore.new(store_identifier)
    block.call(store)

    if options[:primary]
      STORES.unshift(store)
    else
      STORES << store
    end

    STORES_MAP[store_identifier] = store
  end

  def self.stores
    raise "You need to configure add stores to RemoteFile using 'RemoteFile.add_store'" if STORES.empty?
    STORES
  end

  def self.store(store_identifier)
    STORES_MAP[store_identifier]
  end

  def self.primary_store
    STORES.first
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
      raise "invalid call to RemoteFile.synchronize_stores"
    end
  end
end
