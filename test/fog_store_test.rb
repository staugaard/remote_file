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

  describe '#file_from_url' do
    describe 'for an S3 store' do
      before { @store[:provider] = 'AWS' }

      it 'should create a file if the bucket matches' do
        file = @store.file_from_url('http://s3-eu-west-1.amazonaws.com/directory/key/on/s3.txt')
        assert file
        assert_equal 'key/on/s3.txt', file.identifier

        file = @store.file_from_url('http://s3-eu-west-1.amazonaws.com/other_bucket/key/on/s3.txt')
        assert !file

        file = @store.file_from_url('http://storage.cloudfiles.com/directory/key/on/s3.txt')
        assert !file
      end
    end

    describe 'for a cloudfiles store' do
      before { @store[:provider] = 'Rackspace' }

      it 'should create a file if the container matches' do
        file = @store.file_from_url('http://storage.cloudfiles.com/directory/key/on/s3.txt')
        assert file
        assert_equal 'key/on/s3.txt', file.identifier

        file = @store.file_from_url('http://storage.cloudfiles.com/other_container/key/on/s3.txt')
        assert !file

        file = @store.file_from_url('http://s3-eu-west-1.amazonaws.com/directory/key/on/s3.txt')
        assert !file
      end
    end

    describe 'for other stores' do
      before { @store[:provider] = 'Google' }

      it 'should raise a RuntimeError' do
        proc { @store.file_from_url('http://s3-eu-west-1.amazonaws.com/directory/key/on/s3.txt') }.must_raise(RuntimeError)
      end
    end
  end

  describe '#delete!' do
    before do
      @store.directory.files.create(
        :body         => 'content',
        :content_type => 'text/plain',
        :key          => 'identifier',
      )
    end

    it 'should destroy the file' do
      assert @store.directory.files.get('identifier')

      @store.delete!('identifier')

      assert !@store.directory.files.get('identifier')
    end
  end

end
