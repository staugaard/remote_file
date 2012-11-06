require_relative 'test_helper'
require 'remote_files/mock_store'

describe RemoteFiles::Configuration do
  before do
    @configuration = RemoteFiles.configure(:test)
    @file = RemoteFiles::File.new('file', :configuration => :test, :content => 'content', :content_type => 'text/plain')
    @mock_store1 = @configuration.add_store(:mock1, :class => RemoteFiles::MockStore)
    @mock_store2 = @configuration.add_store(:mock2, :class => RemoteFiles::MockStore)
  end

  describe '::add_store' do
    describe 'when adding a non-primary store' do
      before { @non_primary_store = @configuration.add_store(:primary) }

      it 'should add it to the tail of the list of stores' do
        @configuration.stores.must_equal([@mock_store1, @mock_store2, @non_primary_store])
      end
    end

    describe 'when adding a promary store' do
      before { @primary_store = @configuration.add_store(:primary, :primary => true) }

      it 'should add it to the head of the list of stores' do
        @configuration.stores.must_equal([@primary_store, @mock_store1, @mock_store2])
      end
    end
  end

  describe '::primary_store' do
    before do
      @primary_store1 = @configuration.add_store(:primary1, :primary => true)
      @primary_store2 = @configuration.add_store(:primary2, :primary => true)
    end

    it 'should return the head of the list of stores' do
      @configuration.primary_store.must_equal(@primary_store2)
    end
  end

  describe '::lookup_store' do
    before do
      @primary_store = @configuration.add_store(:primary, :primary => true)
    end

    it 'should find the store my identifier' do
      @configuration.lookup_store(:mock1).must_equal(@mock_store1)
      @configuration.lookup_store(:mock2).must_equal(@mock_store2)
      @configuration.lookup_store(:primary).must_equal(@primary_store)
      @configuration.lookup_store(:unknown).must_be_nil
    end
  end

  describe '::store_once!' do

    describe 'when the first store succeeds' do
      before { @configuration.store_once!(@file) }

      it 'should only store the file in the first store' do
        @mock_store1.data['file'].must_equal(:content => 'content', :content_type => 'text/plain')
        @mock_store2.data['file'].must_be_nil
      end
    end

    describe 'when the first store fails' do
      before do
        @mock_store1.expects(:store!).with(@file).raises(RemoteFiles::Error)
        @configuration.store_once!(@file)
      end

      it 'should only store the file in the second store' do
        @mock_store1.data['file'].must_be_nil
        @mock_store2.data['file'].must_equal(:content => 'content', :content_type => 'text/plain')
      end
    end

    describe 'when alls stores fail' do
      before do
        @mock_store1.expects(:store!).with(@file).raises(RemoteFiles::Error)
        @mock_store2.expects(:store!).with(@file).raises(RemoteFiles::Error)
      end

      it 'should raise a RemoteFiles::Error' do
        proc { @configuration.store_once!(@file) }.must_raise(RemoteFiles::Error)
      end
    end
  end

  describe '::store!' do
    describe 'when the file is already stored in some stores' do
      before { @file.stored_in.replace([@mock_store1.identifier]) }

      it 'should not store the file' do
        @configuration.expects(:store_once!).never
        @configuration.store!(@file)
      end

      it 'should synchronize the stores' do
        RemoteFiles.expects(:synchronize_stores).with(@file)
        @configuration.store!(@file)
      end
    end

    describe 'when the file is stored in all stores' do
      before { @file.stored_in.replace([@mock_store1.identifier, @mock_store2.identifier]) }

      it 'should not store the file' do
        @configuration.expects(:store_once!).never
        @configuration.store!(@file)
      end

      it 'should not synchronize the stores' do
        RemoteFiles.expects(:synchronize_stores).never
        @configuration.store!(@file)
      end

    end

    describe 'when the file is not stored anywhere' do
      before { @file.stored_in.replace([]) }

      it 'should store the file once' do
        @file.configuration.expects(:store_once!).with(@file)
        @configuration.store!(@file)
      end

      it 'should synchronize the stores' do
        RemoteFiles.expects(:synchronize_stores).with(@file)
        @configuration.store!(@file)
      end
    end
  end

  describe '::delete_now!' do
    it 'should delete the file from all the stores' do
      @file.stored_in.replace([:mock1, :mock2])
      @mock_store1.expects(:delete!).with(@file.identifier)
      @mock_store2.expects(:delete!).with(@file.identifier)
      @configuration.delete_now!(@file)
    end
  end

  describe '::delete!' do
    describe 'when no handler has been defined' do
      before do
        RemoteFiles.instance_variable_set(:@delete_file, nil)
      end

      it 'deletes the file' do
        @file.expects(:delete_now!)
        @configuration.delete!(@file)
      end
    end

    describe 'when a handler is defined' do
      before do
        @deleted_files = []
        RemoteFiles.delete_file { |file| @deleted_files << file }
      end

      it 'should call the handler' do
        @configuration.delete!(@file)
        @deleted_files.must_equal [@file]
      end
    end
  end

  describe '::synchronize!' do
    describe 'when the file is not stored anywhere' do
      before { @file.stored_in.replace([]) }

      it 'should store the file on all stores' do
        @mock_store1.expects(:store!).returns(true)
        @mock_store2.expects(:store!).returns(true)

        @configuration.synchronize!(@file)
      end
    end

    describe 'when the file is stored in some stores' do
      before { @file.stored_in.replace([@mock_store1.identifier]) }

      it 'should store the file in the remaining stores' do
        @mock_store1.expects(:store!).never
        @mock_store2.expects(:store!).with(@file).returns(true)

        @configuration.synchronize!(@file)
      end
    end

    describe 'when the file is stored everywhere' do
      before { @file.stored_in.replace([@mock_store1.identifier, @mock_store2.identifier]) }

      it 'should not do anything' do
        @mock_store1.expects(:store!).never
        @mock_store2.expects(:store!).never

        @configuration.synchronize!(@file)
      end
    end
  end

  describe '#file_from_url' do
    before do
      @file = @configuration.file_from_url('memory://mock2/foo%40bar', :foo => :bar)
      assert @file
    end

    it 'should unescape the identifier' do
      @file.identifier.must_equal "foo@bar"
    end

    it 'should return a file from this configuration' do
      @file.configuration.must_equal @configuration
    end

    it 'should pass on options' do
      @file.options[:foo].must_equal :bar
    end

    it 'returns nil if the url does not match a store' do
      file = @configuration.file_from_url('http://foo/bar', :foo => :bar)
      file.must_be_nil
    end
  end

end
