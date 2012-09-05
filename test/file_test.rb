require_relative 'test_helper'

describe RemoteFile::File do
  before do
    RemoteFile.add_store(:s3, :primary => true) do |s3|
      s3[:provider] = 'AWS'

      s3[:aws_access_key_id]     = 'access_key_id'
      s3[:aws_secret_access_key] = 'secret_access_key'

      s3[:directory] = 'directory'
      s3[:public]    = true
    end

    RemoteFile.add_store(:cf) do |cf|
      cf[:provider] = 'Rackspace'

      cf[:rackspace_username] = 'rackspace_username'
      cf[:rackspace_api_key]  = 'rackspace_api_key'

      cf[:directory] = 'directory'
      cf[:public]    = true
    end

    @file = RemoteFile::File.new('identifier')
  end

  describe '#stored?' do
    it 'should return true if the file is stored anywhere' do
      @file.stored_in << :s3
      @file.stored?.must_equal(true)
    end

    it 'should return false if the file is not stored anywhere' do
      @file.stored_in.clear
      @file.stored?.must_equal(false)
    end
  end

  describe '#stored_everywhere?' do
    it 'should return false if the file is not stored anywhere' do
      @file.stored_in.clear
      @file.stored_everywhere?.must_equal(false)
    end

    it 'should return false if the file only is stored in some of the stores' do
      @file.stored_in.replace([:s3])
      @file.stored_everywhere?.must_equal(false)
    end

    it 'should return true if the file is stored in all stores' do
      @file.stored_in.replace([:s3, :cf])
      @file.stored_everywhere?.must_equal(true)
    end
  end

  describe '#missing_stores' do
    it 'should give an array of store identifiers where the file is not stored' do
      @file.stored_in.replace([:s3])
      @file.missing_stores.must_equal([:cf])
    end
  end

  describe '#store!' do
    describe 'when the file is already stored in some stores' do
      before { @file.stored_in.replace([:s3]) }

      it 'should just synchronize the stores' do
        RemoteFile.stores.each do |store|
          store.expects(:store!).never
        end

        @file.store!

        $syncs.must_equal([:identifier => 'identifier', :missing_stores => [:cf]])
      end
    end

    describe 'when the file is stored in all stores' do
      before { @file.stored_in.replace([:s3, :cf]) }

      it 'should not do anything' do
        RemoteFile.stores.each do |store|
          store.expects(:store!).never
        end

        @file.store!

        $syncs.must_equal([])
      end
    end

    describe 'when the file is not stored anywhere' do
      before { @file.stored_in.replace([]) }

      describe 'when the primary store is up' do
        before { RemoteFile.primary_store.directory.save }

        it 'should upload the file to the primary store' do
          RemoteFile.primary_store.expects(:store!).with(@file)
          RemoteFile.stores[1].expects(:store!).never

          @file.store!
        end

        it 'should synchronize the stores' do
          @file.store!

          $syncs.must_equal([:identifier => 'identifier', :missing_stores => [:cf]])
        end
      end

      describe 'when the primary store is down' do
        before do
          RemoteFile.primary_store.directory.destroy
          RemoteFile.stores[1].stubs(:store!)
        end

        it 'should upload the file to the next store' do
          RemoteFile.stores[1].expects(:store!).with(@file)

          @file.store!
        end

        it 'should synchronize the stores' do
          @file.store!

          $syncs.must_equal([:identifier => 'identifier', :missing_stores => [:s3]])
        end
      end

      describe 'when all stores are down' do
        before do
          RemoteFile.stores.each do |store|
            store.stubs(:store!).raises(RemoteFile::Error)
          end
        end

        it 'should raise a RemoteFile::Error' do
          proc { @file.store! }.must_raise(RemoteFile::Error)
        end
      end
    end
  end

  describe '#synchronize!' do
    before do
      RemoteFile.stores.each do |store|
        store.stubs(:store!).returns(true)
      end
    end

    describe 'when the file is not stored anywhere' do
      before { @file.stored_in.replace([]) }

      it 'should store the file on all stores' do
        RemoteFile.stores.each do |store|
          store.expects(:store!).with(@file).returns(true)
        end

        @file.synchronize!
      end
    end

    describe 'when the file is stored in some stores' do
      before { @file.stored_in.replace([:s3]) }

      it 'should store the file in the remaining stores' do
        RemoteFile.store(:s3).expects(:store!).never
        RemoteFile.store(:cf).expects(:store!).with(@file).returns(true)

        @file.synchronize!
      end
    end

    describe 'when the file is stored everywhere' do
      before { @file.stored_in.replace([:s3, :cf]) }

      it 'should not do anything' do
        RemoteFile.stores.each do |store|
          store.expects(:store!).never
        end

        @file.synchronize!
      end
    end
  end
end
