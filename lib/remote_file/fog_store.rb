require 'remote_file/abstract_store'
require 'fog'

module RemoteFile
  class FogStore < AbstractStore
    def store!(file)
      sucess = directory.files.create(
        :body         => file.content,
        :content_type => file.content_type,
        :key          => file.identifier,
        :public       => options[:public]
      )

      raise RemoteFile::Error unless sucess

      true
    rescue Fog::Errors::Error, Excon::Errors::Error
      raise RemoteFile::Error, $!.message, $!.backtrace
    end

    def retrieve!(identifier)
      fog_file = directory.files.get(identifier)

      raise NotFoundError, "#{identifier} not found in #{self.identifier} store" if fog_file.nil?

      File.new(identifier,
        :content      => fog_file.body,
        :content_type => fog_file.content_type,
        :stored_in    => [self.identifier]
      )
    rescue Fog::Errors::Error, Excon::Errors::Error
      raise RemoteFile::Error, $!.message, $!.backtrace
    end

    def options
      @options ||= {}
    end

    def []=(name, value)
      options[name] = value
    end

    def connection
      connection_options = options.dup
      connection_options.delete(:directory)
      connection_options.delete(:public)
      @connection ||= Fog::Storage.new(connection_options)
    end

    def directory
      @directory ||= connection.directories.new(
        :key    => options[:directory],
        :public => options[:public]
      )
    end
  end
end
