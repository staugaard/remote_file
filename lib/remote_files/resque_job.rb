require 'remote_files'
require 'resque'

module RemoteFiles
  class ResqueJob
    def self.perform(options)
      identifier = options.delete(:identifier) || options.delete("identifier")
      action     = options.delete(:_action)    || options.delete("_action")

      file = RemoteFiles::File.new(identifier, options)

      case action.to_sym
      when :synchronize
        file.synchronize!
      when :delete
        file.delete_now!
      else
        raise "unknown action #{action.inspect}"
      end
    end
  end

  synchronize_stores do |file|
    Resque.enqueue(ResqueJob, file.options.merge(:_action => :synchronize))
  end

  delete_file do |file|
    Resque.enqueue(ResqueJob, file.options.merge(:_action => :delete))
  end
end
