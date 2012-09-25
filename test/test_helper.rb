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

    $syncs = []
    RemoteFiles.synchronize_stores do |file|
      $syncs << {:identifier => file.identifier, :missing_stores => file.missing_stores}
    end
  end
end
