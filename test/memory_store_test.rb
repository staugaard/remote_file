require_relative 'test_helper'
require 'remote_files/memory_store'

describe RemoteFiles::MemoryStore do
  before do
    @store = RemoteFiles::MemoryStore.new(:mem)
  end

  describe '#store!' do
    before do
      @file = RemoteFiles::File.new('identifier', :content_type => 'text/plain', :content => 'content')
    end

    it 'should store the file in the memory' do
      @store.store!(@file)

      assert_equal({:content_type => 'text/plain', :content => 'content'}, @store.data['identifier'])
    end
  end

  describe '#retrieve!' do
    it 'should return a RemoteFiles::File when found' do
      @store.data['identifier'] = {:content_type => 'text/plain', :content => 'content'}

      file = @store.retrieve!('identifier')

      file.must_be_instance_of(RemoteFiles::File)
      file.content.must_equal('content')
      file.content_type.must_equal('text/plain')
    end

    it 'should raise a RemoteFiles::NotFoundError when not found' do
      proc { @store.retrieve!('identifier') }.must_raise(RemoteFiles::NotFoundError)
    end
  end

  describe '#url' do
    it 'should return a fake memory url' do
      @store.url('identifier').must_equal('memory://mem/identifier')
    end
  end

  describe '#file_from_url' do
    it 'should create a file if the store identifier matches' do
      file = @store.file_from_url('memory://mem/identifier')
      assert file
      assert_equal 'identifier', file.identifier

      file = @store.file_from_url('memory://other_store/identifier')
      assert !file

      file = @store.file_from_url('https://s3.amazonaws.com/mem/identifier')
      assert !file
    end
  end

  describe '#delete!' do
    before do
      @store.data['identifier'] = {:content_type => 'text/plain', :content => 'content'}
    end

    it 'raises a NotFoundError if the file does not exist' do
      lambda { @store.delete!('unknown') }.must_raise(RemoteFiles::NotFoundError)
    end

    it 'should destroy the file' do
      assert @store.data['identifier']

      @store.delete!('identifier')

      assert !@store.data['identifier']
    end
  end


  describe '#directory_name' do
    it 'returns the store identifier' do
      @store.directory_name.must_equal 'mem'
    end
  end

end
