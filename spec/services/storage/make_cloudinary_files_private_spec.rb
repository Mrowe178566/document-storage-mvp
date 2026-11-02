require "rails_helper"

RSpec.describe Storage::MakeCloudinaryFilesPrivate do
  def cloudinary_blob(key, filename, content_type)
    ActiveStorage::Blob.create!(
      key: key, filename: filename, content_type: content_type,
      byte_size: 10, checksum: "x", service_name: "cloudinary"
    )
  end

  let!(:pdf)  { cloudinary_blob("pdfkey", "plan.pdf", "application/pdf") }
  let!(:text) { cloudinary_blob("txtkey", "notes.txt", "text/plain") }
  let!(:local_file) do
    ActiveStorage::Blob.create!(
      key: "diskkey", filename: "local.pdf", content_type: "application/pdf",
      byte_size: 10, checksum: "x", service_name: "test"
    )
  end

  let(:output) { StringIO.new }

  before { allow(Cloudinary::Uploader).to receive(:rename) }

  it "only reports what it would change unless told to apply" do
    result = described_class.call(output: output)

    expect(Cloudinary::Uploader).not_to have_received(:rename)
    expect(result.total).to eq(2)
    expect(result.changed).to be_empty
    expect(output.string).to include("Dry run", "pdfkey", "txtkey.txt")
  end

  it "switches each Cloudinary file from public to authenticated, in place" do
    result = described_class.call(apply: true, output: output)

    expect(Cloudinary::Uploader).to have_received(:rename).with(
      "pdfkey", "pdfkey",
      hash_including(type: "upload", to_type: "authenticated", resource_type: "image", invalidate: true)
    )
    # Cloudinary stores non-image files as "raw", with the extension in the ID.
    expect(Cloudinary::Uploader).to have_received(:rename).with(
      "txtkey.txt", "txtkey.txt",
      hash_including(type: "upload", to_type: "authenticated", resource_type: "raw")
    )
    expect(result.changed).to eq(%w[pdfkey txtkey.txt])
  end

  it "uses the credentials from config/storage.yml" do
    described_class.call(apply: true, output: output)

    config = Rails.configuration.active_storage.service_configurations.fetch("cloudinary")
    expect(Cloudinary::Uploader).to have_received(:rename)
      .with(anything, anything, hash_including(api_key: config["api_key"], api_secret: config["api_secret"]))
      .twice
  end

  it "skips files that aren't on Cloudinary" do
    described_class.call(apply: true, output: output)

    expect(Cloudinary::Uploader).not_to have_received(:rename).with("diskkey", any_args)
  end

  it "can be tried on a few files first" do
    result = described_class.call(apply: true, limit: 1, output: output)

    expect(Cloudinary::Uploader).to have_received(:rename).once
    expect(result.changed).to eq(%w[pdfkey])
  end

  context "when there's no public copy to switch" do
    before do
      allow(Cloudinary::Uploader).to receive(:rename)
        .with("pdfkey", any_args).and_raise(CloudinaryException, "Resource not found - pdfkey")
    end

    # Re-running after a partial run (e.g. LIMIT=1) hits files it already switched.
    it "reports files that are already authenticated, not as failures" do
      allow(Cloudinary::Api).to receive(:resource)
        .with("pdfkey", hash_including(type: "authenticated", resource_type: "image"))
        .and_return({ "public_id" => "pdfkey" })

      result = described_class.call(apply: true, output: output)

      expect(result.already_private).to eq(%w[pdfkey])
      expect(result.failed).to be_empty
      expect(result.changed).to eq(%w[txtkey.txt])
      expect(output.string).to include("already private pdfkey")
    end

    it "keeps going when a file is missing entirely, and reports it" do
      allow(Cloudinary::Api).to receive(:resource).and_raise(Cloudinary::Api::NotFound, "Resource not found")

      result = described_class.call(apply: true, output: output)

      expect(result.changed).to eq(%w[txtkey.txt])
      expect(result.failed).to eq([ [ "pdfkey", "Resource not found - pdfkey" ] ])
      expect(output.string).to include("FAILED pdfkey")
    end
  end
end
