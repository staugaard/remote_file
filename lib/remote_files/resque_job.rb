require 'remote_files'
require 'resque'

module RemoteFiles
  class ResqueJob
    def self.perform(options)
      file = RemoteFiles::File.new(options.delete(:identifier), options)
      file.synchronize!
    end
  end

  synchronize_stores do |file|
    Resque.enqueue(ResqueJob, file.options)
  end
end
