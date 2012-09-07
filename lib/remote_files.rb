require 'remote_files/version'
require 'remote_files/fog_store'
require 'remote_files/file'

module RemoteFiles
  class Error < StandardError; end
  class NotFoundError < Error; end

  STORES_MAP = {}
  STORES = []

  def self.add_store(store_identifier, options = {}, &block)
    store = (options[:class] || FogStore).new(store_identifier)
    block.call(store) if block_given?

    if options[:primary]
      STORES.unshift(store)
    else
      STORES << store
    end

    STORES_MAP[store_identifier] = store
  end

  def self.stores
    raise "You need to configure add stores to RemoteFiles using 'RemoteFiles.add_store'" if STORES.empty?
    STORES
  end

  def self.lookup_store(store_identifier)
    STORES_MAP[store_identifier]
  end

  def self.primary_store
    STORES.first
  end

  def self.store_once!(file)
    return file.stored_in.first if file.stored?

    exception = nil

    stores.each do |store|
      begin
        stored = store.store!(file)
        file.stored_in << store.identifier
        break
      rescue ::RemoteFiles::Error => e
        exception = e
      end
    end

    raise exception unless file.stored?

    file.stored_in.first
  end

  def self.store!(file)
    store_once!(file) unless file.stored?

    synchronize_stores(file) unless file.stored_everywhere?

    true
  end

  def self.delete!(file)
    file.stored_in.each do |store_identifier|
      store = lookup_store(store_identifier)
      store.delete!(file.identifier)
    end
  end

  def self.synchronize!(file)
    file.missing_stores.each do |store_identifier|
      store = lookup_store(store_identifier)
      store.store!(file)
      file.stored_in << store.identifier
    end
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
