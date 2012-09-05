require_relative 'test_helper'

describe RemoteFile::FogStore do
  before do
    @connection = Fog::Storage.new({
      :provider              => 'AWS',
      :aws_access_key_id     => 'access_key_id',
      :aws_secret_access_key => 'secret_access_key'
    })

    @directory = @connection.directories.create(:key => 'directory')

    @store = RemoteFile::FogStore.new(:fog)
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
      @file = RemoteFile::File.new('identifier', :content_type => 'text/plain', :content => 'content')
    end

    it 'should store the file in the directory' do
      @store.store!(@file)

      fog_file = @directory.files.get('identifier')

      fog_file.must_be_instance_of(Fog::Storage::AWS::File)
      fog_file.content_type.must_equal('text/plain')
      fog_file.body.must_equal('content')
    end

    it 'should raise a RemoteFile::Error when an error happens' do
      @directory.destroy
      proc { @store.store!(@file) }.must_raise(RemoteFile::Error)
    end
  end

  describe '#retrieve!' do
    it 'should return a RemoteFile::File when found' do
      @directory.files.create(
        :body         => 'content',
        :content_type => 'text/plain',
        :key          => 'identifier'
      )

      file = @store.retrieve!('identifier')

      file.must_be_instance_of(RemoteFile::File)
      file.content.must_equal('content')
      file.content_type.must_equal('text/plain')
    end

    it 'should raise a RemoteFile::NotFoundError when not found' do
      proc { @store.retrieve!('identifier') }.must_raise(RemoteFile::NotFoundError)
    end

    it 'should raise a RemoteFile::Error when error' do
      @directory.destroy
      proc { @store.retrieve!('identifier') }.must_raise(RemoteFile::Error)
    end
  end
end
