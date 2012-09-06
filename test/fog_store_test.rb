require_relative 'test_helper'

describe RemoteFiles::FogStore do
  before do
    @connection = Fog::Storage.new({
      :provider              => 'AWS',
      :aws_access_key_id     => 'access_key_id',
      :aws_secret_access_key => 'secret_access_key'
    })

    @directory = @connection.directories.create(:key => 'directory')

    @store = RemoteFiles::FogStore.new(:fog)
    @store[:provider] = 'AWS'
    @store[:aws_access_key_id]     = 'access_key_id'
    @store[:aws_secret_access_key] = 'secret_access_key'
    @store[:directory] = 'directory'
    @store[:public]    = true
  end

  describe 'configuration' do
    it 'should configure a fog connection' do
      connection = @store.connection

      connection.must_be_instance_of(Fog::Storage::AWS::Mock)
    end

    it 'should configure directory' do
      directory = @store.directory

      directory.must_be_instance_of(Fog::Storage::AWS::Directory)

      directory.key.must_equal('directory')
    end
  end

  describe '#store!' do
    before do
      @file = RemoteFiles::File.new('identifier', :content_type => 'text/plain', :content => 'content')
    end

    it 'should store the file in the directory' do
      @store.store!(@file)

      fog_file = @directory.files.get('identifier')

      fog_file.must_be_instance_of(Fog::Storage::AWS::File)
      fog_file.content_type.must_equal('text/plain')
      fog_file.body.must_equal('content')
    end

    it 'should raise a RemoteFiles::Error when an error happens' do
      @directory.destroy
      proc { @store.store!(@file) }.must_raise(RemoteFiles::Error)
    end
  end

  describe '#retrieve!' do
    it 'should return a RemoteFiles::File when found' do
      @directory.files.create(
        :body         => 'content',
        :content_type => 'text/plain',
        :key          => 'identifier'
      )

      file = @store.retrieve!('identifier')

      file.must_be_instance_of(RemoteFiles::File)
      file.content.must_equal('content')
      file.content_type.must_equal('text/plain')
    end

    it 'should raise a RemoteFiles::NotFoundError when not found' do
      proc { @store.retrieve!('identifier') }.must_raise(RemoteFiles::NotFoundError)
    end

    it 'should raise a RemoteFiles::Error when error' do
      @directory.destroy
      proc { @store.retrieve!('identifier') }.must_raise(RemoteFiles::Error)
    end
  end

  describe '#url' do
    describe 'for S3 connections' do
      before { @store[:provider] = 'AWS' }

      it 'should return an S3 url' do
        @store.url('identifier').must_equal('https://s3.amazonaws.com/directory/identifier')
      end
    end

    describe 'for CloudFiles connections' do
      before { @store[:provider] = 'Rackspace' }

      it 'should return a CloudFiles url' do
        @store.url('identifier').must_equal('https://storage.cloudfiles.com/directory/identifier')
      end
    end

    describe 'for other connections' do
      before { @store[:provider] = 'Google' }

      it 'should raise' do
        proc { @store.url('identifier') }.must_raise(RuntimeError)
      end
    end
  end
end
