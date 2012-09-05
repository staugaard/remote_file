require 'test_helper'

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

  end

  describe '#stored?' do
    it 'should return true if the file is stored anywhere'
    it 'should return false if the file is not stored anywhere'
  end

  describe '#stored_everywhere?' do
    it 'should return false if the file is not stored anywhere'
    it 'should return false if the file only is stored in some of the stores'
    it 'should return true if the file is stored in all stores'
  end

  describe '#missing_stores' do
    it 'should give an array of store identifiers where the file is not stored'
  end

  describe '#store!' do
    describe 'when the file is already stored in some stores' do
      it 'should just syncronize the stores'
    end

    describe 'when the file is stored in all stores' do
      it 'should not do anything'
    end

    describe 'when the file is not stored anywhere' do
      describe 'when the primary store is up' do
        it 'should upload the file to the primary store'
        it 'should syncronize the stores'
      end

      describe 'when the primary store is down' do
        it 'should upload the file to the next store'
        it 'should syncronize the stores'
      end

      describe 'when all stores are down' do
        it 'should raise a RemoteFile::Error'
      end
    end
  end

  it 'sdf' do
    
  end
end
