require 'bundler/setup'

require 'debugger'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'remote_files'

require 'minitest/autorun'

require 'mocha'

Fog.mock!

MiniTest::Spec.class_eval do
  before do
    Fog::Mock.reset

    RemoteFiles::CONFIGURATIONS.values.each do |conf|
      conf.clear
    end

    RemoteFiles.synchronize_stores do |file|
    end

    RemoteFiles.delete_file do |file|
    end
  end
end
