require_relative 'test_helper'

describe RemoteFiles do
  describe '::synchronize_stores' do
    before do
      @files = []

      RemoteFiles.synchronize_stores do |file|
        @files << file
      end
    end

    it 'should use the block for store synchronizaation' do
      file = RemoteFiles::File.new('file')
      RemoteFiles.synchronize_stores(file)
      @files.must_equal([file])
    end
  end

end
