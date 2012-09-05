require_relative 'test_helper'
require 'remote_file/mock_store'

describe RemoteFile do
  before do
    @file = RemoteFile::File.new('file', :content => 'content', :content_type => 'text/plain')
    @mock_store1 = RemoteFile.add_store(:mock1, :class => RemoteFile::MockStore)
    @mock_store2 = RemoteFile.add_store(:mock2, :class => RemoteFile::MockStore)
  end

  describe '::add_store' do
    describe 'when adding a non-primary store' do
      before { @non_primary_store = RemoteFile.add_store(:primary) }

      it 'should add it to the tail of the list of stores' do
        RemoteFile.stores.must_equal([@mock_store1, @mock_store2, @non_primary_store])
      end
    end

    describe 'when adding a promary store' do
      before { @primary_store = RemoteFile.add_store(:primary, :primary => true) }

      it 'should add it to the head of the list of stores' do
        RemoteFile.stores.must_equal([@primary_store, @mock_store1, @mock_store2])
      end
    end
  end

  describe '::primary_store' do
    before do
      @primary_store1 = RemoteFile.add_store(:primary1, :primary => true)
      @primary_store2 = RemoteFile.add_store(:primary2, :primary => true)
    end

    it 'should return the head of the list of stores' do
      RemoteFile.primary_store.must_equal(@primary_store2)
    end
  end

  describe '::lookup_store' do
    before do
      @primary_store = RemoteFile.add_store(:primary, :primary => true)
    end

    it 'should find the store my identifier' do
      RemoteFile.lookup_store(:mock1).must_equal(@mock_store1)
      RemoteFile.lookup_store(:mock2).must_equal(@mock_store2)
      RemoteFile.lookup_store(:primary).must_equal(@primary_store)
      RemoteFile.lookup_store(:unknown).must_be_nil
    end
  end

  describe '::store_once!' do

    describe 'when the first store succeeds' do
      before { RemoteFile.store_once!(@file) }

      it 'should only store the file in the first store' do
        @mock_store1.data['file'].must_equal(:content => 'content', :content_type => 'text/plain')
        @mock_store2.data['file'].must_be_nil
      end
    end

    describe 'when the first store fails' do
      before do
        @mock_store1.expects(:store!).with(@file).raises(RemoteFile::Error)
        RemoteFile.store_once!(@file)
      end

      it 'should only store the file in the second store' do
        @mock_store1.data['file'].must_be_nil
        @mock_store2.data['file'].must_equal(:content => 'content', :content_type => 'text/plain')
      end
    end

    describe 'when alls stores fail' do
      before do
        @mock_store1.expects(:store!).with(@file).raises(RemoteFile::Error)
        @mock_store2.expects(:store!).with(@file).raises(RemoteFile::Error)
      end

      it 'should raise a RemoteFile::Error' do
        proc { RemoteFile.store_once!(@file) }.must_raise(RemoteFile::Error)
      end
    end
  end

  describe '::synchronize_stores' do
    before do
      @files = []

      RemoteFile.synchronize_stores do |file|
        @files << file
      end
    end

    it 'should use the block for store synchronizaation' do
      file = RemoteFile::File.new('file')
      RemoteFile.synchronize_stores(file)
      @files.must_equal([file])
    end
  end

  describe '::store!' do
    describe 'when the file is already stored in some stores' do
      before { @file.stored_in.replace([@mock_store1.identifier]) }

      it 'should not store the file' do
        RemoteFile.expects(:store_once!).never
        RemoteFile.store!(@file)
      end

      it 'should synchronize the stores' do
        RemoteFile.expects(:synchronize_stores).with(@file)
        RemoteFile.store!(@file)
      end
    end

    describe 'when the file is stored in all stores' do
      before { @file.stored_in.replace([@mock_store1.identifier, @mock_store2.identifier]) }

      it 'should not store the file' do
        RemoteFile.expects(:store_once!).never
        RemoteFile.store!(@file)
      end

      it 'should not synchronize the stores' do
        RemoteFile.expects(:synchronize_stores).never
        RemoteFile.store!(@file)
      end

    end

    describe 'when the file is not stored anywhere' do
      before { @file.stored_in.replace([]) }

      it 'should store the file once' do
        RemoteFile.expects(:store_once!).with(@file)
        RemoteFile.store!(@file)
      end

      it 'should synchronize the stores' do
        RemoteFile.expects(:synchronize_stores).with(@file)
        RemoteFile.store!(@file)
      end
    end
  end

  describe '::synchronize!' do
    describe 'when the file is not stored anywhere' do
      before { @file.stored_in.replace([]) }

      it 'should store the file on all stores' do
        @mock_store1.expects(:store!).returns(true)
        @mock_store2.expects(:store!).returns(true)

        RemoteFile.synchronize!(@file)
      end
    end

    describe 'when the file is stored in some stores' do
      before { @file.stored_in.replace([@mock_store1.identifier]) }

      it 'should store the file in the remaining stores' do
        @mock_store1.expects(:store!).never
        @mock_store2.expects(:store!).with(@file).returns(true)

        RemoteFile.synchronize!(@file)
      end
    end

    describe 'when the file is stored everywhere' do
      before { @file.stored_in.replace([@mock_store1.identifier, @mock_store2.identifier]) }

      it 'should not do anything' do
        @mock_store1.expects(:store!).never
        @mock_store2.expects(:store!).never

        RemoteFile.synchronize!(@file)
      end
    end
  end

end
