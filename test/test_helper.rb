require 'bundler/setup'

require 'minitest/autorun'
require 'minitest/rg'
require 'mocha/setup'
require 'fog'


$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require 'remote_files'
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
