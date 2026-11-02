module Storage
  # One-time switch for files uploaded before Cloudinary delivery became
  # "authenticated" (see config/storage.yml). Each public ("upload") file is
  # renamed in place to type "authenticated", so its old public URL stops
  # working and the signed URLs the app now builds can find it.
  #
  # Dry run unless apply: true. Safe to re-run: a file that was already
  # switched comes back from Cloudinary as not found, which is reported as a
  # failure and changes nothing.
  #
  # Usage:
  #   result = Storage::MakeCloudinaryFilesPrivate.call(apply: true, limit: 3)
  #   result.changed # => public IDs that were switched
  #   result.failed  # => [[public_id, error message], ...]
  class MakeCloudinaryFilesPrivate
    SERVICE_NAME = "cloudinary".freeze

    Result = Struct.new(:total, :changed, :failed, keyword_init: true)

    def self.call(apply: false, limit: nil, output: $stdout)
      new(apply: apply, limit: limit, output: output).call
    end

    def initialize(apply:, limit:, output:)
      @apply  = apply
      @limit  = limit
      @output = output
    end

    def call
      blobs = ActiveStorage::Blob.where(service_name: SERVICE_NAME).order(:id)
      blobs = blobs.limit(@limit) if @limit
      result = Result.new(total: blobs.size, changed: [], failed: [])

      @output.puts "Dry run: nothing will change. Set CONFIRM=1 to apply." unless @apply
      blobs.each { |blob| switch(blob, result) }
      @output.puts "#{result.total} files, #{result.changed.size} switched, #{result.failed.size} failed."
      result
    end

    private

    def switch(blob, result)
      public_id, resource_type = locate(blob)

      unless @apply
        @output.puts "would switch #{public_id} (#{resource_type})"
        return
      end

      Cloudinary::Uploader.rename(
        public_id, public_id,
        type: "upload", to_type: "authenticated", resource_type: resource_type,
        invalidate: true, **credentials
      )
      result.changed << public_id
      @output.puts "switched #{public_id}"
    rescue CloudinaryException => e
      result.failed << [ public_id, e.message ]
      @output.puts "FAILED #{public_id}: #{e.message}"
    end

    # Asks the Cloudinary service itself, so the public ID (raw files keep
    # their extension) and resource type match exactly what it uploaded.
    def locate(blob)
      service = blob.service
      key = ActiveStorage::BlobKey.new(blob.attributes.as_json)
      [ service.public_id(key), service.send(:resource_type, nil, key) ]
    end

    # The app only passes Cloudinary keys through config/storage.yml, so the
    # rename call needs them too.
    def credentials
      Rails.configuration.active_storage.service_configurations
           .fetch(SERVICE_NAME).symbolize_keys
           .slice(:cloud_name, :api_key, :api_secret)
    end
  end
end
