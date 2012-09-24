require 'remote_files/abstract_store'
require 'fog'

module RemoteFiles
  class FogStore < AbstractStore
    def store!(file)
      success = directory.files.create(
        :body         => file.content,
        :content_type => file.content_type,
        :key          => file.identifier,
        :public       => options[:public]
      )

      raise RemoteFiles::Error unless success

      true
    rescue Fog::Errors::Error, Excon::Errors::Error
      raise RemoteFiles::Error, $!.message, $!.backtrace
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
      raise RemoteFiles::Error, $!.message, $!.backtrace
    end

    def url(identifier)
      case options[:provider]
      when 'AWS'
        "https://s3.amazonaws.com/#{options[:directory]}/#{Fog::AWS.escape(identifier)}"
      when 'Rackspace'
        "https://storage.cloudfiles.com/#{options[:directory]}/#{Fog::Rackspace.escape(identifier, '/')}"
      else
        raise "#{self.class.name}#url was not implemented for the #{options[:provider]} provider"
      end
    end

    def url_matcher
      @url_matcher ||= case options[:provider]
      when 'AWS'
        /https?:\/\/s3[^\.]*.amazonaws.com\/#{options[:directory]}\/(.*)/
      when 'Rackspace'
        /https?:\/\/storage.cloudfiles.com\/#{options[:directory]}\/(.*)/
      else
        raise "#{self.class.name}#url_matcher was not implemented for the #{options[:provider]} provider"
      end
    end

    def delete!(identifier)
      connection.delete_object(directory.key, identifier)
    end

    def connection
      connection_options = options.dup
      connection_options.delete(:directory)
      connection_options.delete(:public)
      @connection ||= Fog::Storage.new(connection_options)
    end

    def directory
      @directory ||= lookup_directory || create_directory
    end

    protected

    def lookup_directory
      connection.directories.get(options[:directory])
    end

    def create_directory
      connection.directories.new(
        :key => options[:directory],
        :public => options[:public]
      ).tap do |dir|
        dir.save
      end
    end
  end
end
