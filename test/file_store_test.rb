require_relative 'test_helper'
require 'remote_files/file_store'

describe RemoteFiles::FileStore do
  before do
    @directory = Pathname.new(File.dirname(__FILE__)) + '../tmp'

    @store = RemoteFiles::FileStore.new(:file)
    @store[:directory] = @directory
  end

  describe '#store!' do
    before do
      @file = RemoteFiles::File.new('foo/identifier', :content_type => 'text/plain', :content => content)
    end

    def self.it_should_store_file
      it 'should store the file on disk' do
        @store.store!(@file)

        file_path = @directory + 'foo/identifier'
        file_path.exist?

        assert_equal 'content', file_path.read
      end
    end

    describe "content = string" do
      let(:content) { "content" }
      it_should_store_file
    end

    describe "content = stringio" do
      let(:content) { StringIO.new("content") }
      it_should_store_file
    end

    describe "content = io" do
      let(:content) do
        mock('IO').tap do |io|
          io.stubs(:read).returns("content").then.returns(nil)
        end
      end

      it_should_store_file
    end
  end

  describe '#retrieve!' do
    it 'should return a RemoteFiles::File when found' do
      (@store.directory + 'identifier').open('w') do |f|
        f.write('content')
      end

      file = @store.retrieve!('identifier')

      file.must_be_instance_of(RemoteFiles::File)
      file.content.must_equal('content')
      # file.content_type.must_equal('text/plain')
    end

    it 'should raise a RemoteFiles::NotFoundError when not found' do
      (@store.directory + 'identifier').delete rescue nil
      proc { @store.retrieve!('identifier') }.must_raise(RemoteFiles::NotFoundError)
    end
  end

  describe '#url' do
    it 'should return a file url' do
      @store.url('identifier').must_equal("file://localhost#{@directory}/identifier")
    end
  end

  describe '#file_from_url' do
    it 'should create a file if the directory matches' do
      file = @store.file_from_url("file://localhost#{@directory}/identifier")
      assert file
      assert_equal 'identifier', file.identifier

      file = @store.file_from_url("file://localhost#{@directory}_other/identifier")
      assert !file

      file = @store.file_from_url('https://s3.amazonaws.com/mem/identifier')
      assert !file
    end
  end

  describe '#delete!' do
    before do
      (@store.directory + 'identifier').open('w') do |f|
        f.write('content')
      end
    end

    it 'raises a NotFoundError if the file does not exist' do
      lambda { @store.delete!('unknown') }.must_raise(RemoteFiles::NotFoundError)
    end

    it 'should destroy the file' do
      assert (@store.directory + 'identifier').exist?

      @store.delete!('identifier')

      assert !(@store.directory + 'identifier').exist?
    end
  end

  describe '#directory_name' do
    it 'returns the name of the directory' do
      @store.directory_name.must_equal @directory.to_s
    end
  end

end
