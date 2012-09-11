# RemoteFiles

A library for uploading files to multiple remote storage backends like Amazon S3 and Rackspace CloudFiles.

The purpose of the library is to implement a simple interface for uploading files to multiple backends
and to keep the backends in sync, so that your app will keep working when one backend is down.

## Installation

Add this line to your application's Gemfile:

    gem 'remote_files'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install remote_files

## Configuration

First you configure the storage backends you want:

```ruby
RemoteFiles.add_store(:s3, :primary => true) do |s3|
  s3[:provider] = 'AWS'

  s3[:aws_access_key_id]     = AWS_ACCESS_KEY_ID
  s3[:aws_secret_access_key] = AWS_SECRET_ACCESS_KEY

  s3[:directory] = 'my_s3_bucket'
end

RemoteFiles.add_store(:cf) do |cf|
  cf[:provider] = 'Rackspace'

  cf[:rackspace_username] = RACKSPACE_USERNAME
  cf[:rackspace_api_key]  = RACKSPACE_API_KEY

  cf[:directory] = 'my_cf_container'
end
```

By default RemoteFiles will store your files to all stores synchronously. This is probably not what you want,
so you should tell RemoteFiles how to do it asynchronously:

```ruby
class RemoteFilesSyncJob
  def initialize(identifier, stored_in)
    @file = RemoteFiles::File.new(identifier, :stored_in => stored_in)
  def

  def work
    @file.synchronize!
  end
end

RemoteFiles.synchronize_stores do |file|
  MyPreferredJobQueue.enqueue(RemoteFilesSyncJob, file.identifier, file.stored_in)
end
```

## Usage

Once everything is configured, you can store files like this:

```ruby
file = RemoteFiles::File.new(unique_file_name, :content => file_content, :content_type => content_type)
file.store!
```

This will store the file on one of the stores and then asynchronously copy the file to the remaining stores.
`RemoteFiles::File#store!` will raise a `RemoteFiles::Error` if all storage backends are down.

If you just need to store the file in a single store, the you can use `RemoteFiles::File#store_once!`. It will
behave exactly like `RemoteFiles::File#store!`, but will not asynchronously copy the file to the other stores.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request