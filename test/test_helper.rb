require 'bundler/setup'

require 'debugger'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'remote_file'

require 'minitest/autorun'

require 'webmock/minitest'
WebMock.disable_net_connect!

Fog.mock!

MiniTest::Spec.class_eval do
  before do
    Fog::Mock.reset
    RemoteFile::STORES.clear
    RemoteFile::STORES_MAP.clear
  end
end
