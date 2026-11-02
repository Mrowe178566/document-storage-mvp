require "rails_helper"
require "active_storage/service/cloudinary_service"

# Files on Cloudinary use "authenticated" delivery: a plain Cloudinary URL
# doesn't open them, only a URL signed with the API secret does. The app
# builds those signed URLs on the server and never sends them to a browser
# (StoredFilesController#download streams the file instead).
#
# Tests run on the Disk service, so these build the real Cloudinary service
# from config/storage.yml with fake credentials. Nothing here calls Cloudinary.
RSpec.describe "Cloudinary storage settings" do
  let(:config) do
    Rails.configuration.active_storage.service_configurations.fetch("cloudinary").symbolize_keys
  end
  let(:service) do
    ActiveStorage::Service::CloudinaryService.new(
      **config.except(:service).merge(cloud_name: "demo", api_key: "123", api_secret: "secret")
    )
  end
  let(:blob) do
    ActiveStorage::Blob.create!(
      key: "abc123", filename: "plan.pdf", content_type: "application/pdf",
      byte_size: 10, checksum: "x", service_name: "test"
    )
  end
  let(:blob_key) { ActiveStorage::BlobKey.new(blob.attributes.as_json) }

  it "uses authenticated delivery with signed URLs" do
    expect(config).to include(type: "authenticated", sign_url: true)
  end

  it "builds signed, authenticated URLs instead of public ones" do
    url = service.url(blob_key)

    expect(url).to include("/image/authenticated/s--")
    expect(url).not_to include("/upload/")
  end

  it "uploads new files as authenticated" do
    allow(Cloudinary::Uploader).to receive(:upload_large)

    service.upload(blob_key, StringIO.new("%PDF-1.4"))

    expect(Cloudinary::Uploader).to have_received(:upload_large)
      .with(anything, hash_including(type: "authenticated"))
  end

  it "deletes the authenticated copy" do
    allow(Cloudinary::Uploader).to receive(:destroy)

    service.delete(blob_key)

    expect(Cloudinary::Uploader).to have_received(:destroy)
      .with("abc123", hash_including(type: "authenticated"))
  end
end
