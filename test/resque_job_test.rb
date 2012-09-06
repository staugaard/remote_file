require_relative 'test_helper'
require 'remote_files/resque_job'

describe RemoteFiles::ResqueJob do
  describe 'loading the implementation file' do
    before { load 'remote_files/resque_job.rb' }

    it 'should setup the right synchronize_stores hook' do
      file = RemoteFiles::File.new('identifier',
        :content_type => 'text/plain',
        :content => 'content',
        :stored_in => [:s3],
        :foo => :bar
      )

      Resque.expects(:enqueue).with(RemoteFiles::ResqueJob,
        :identifier => 'identifier',
        :content_type => 'text/plain',
        :stored_in => [:s3],
        :foo => :bar
      )

      RemoteFiles.synchronize_stores(file)
    end
  end

  it 'should call #synchronize! on the reconstructed file' do
    options = {
      :identifier => 'identifier',
      :content_type => 'text/plain',
      :stored_in => [:s3],
      :foo => :bar
    }

    file = stub
    file.expects(:synchronize!)

    RemoteFiles::File.expects(:new).with('identifier',
      :content_type => 'text/plain',
      :stored_in => [:s3],
      :foo => :bar
    ).returns(file)

    RemoteFiles::ResqueJob.perform(options)
  end
end
