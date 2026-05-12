require "rails_helper"

RSpec.describe StoredFile, type: :model do
  let(:user) { User.create!(email: "test@example.com", password: "password") }
  let(:workspace) { user.workspace }
  let(:folder) { workspace.folders.create!(name: "Test Folder", user: user) }

  def build_file(file_name:, content_type: "application/pdf", byte_size: 1.kilobyte, content: "x")
    file = workspace.stored_files.build(
      file_name: file_name,
      user: user,
      folder: folder
    )
    file.uploaded_file.attach(
      io: StringIO.new(content * byte_size),
      filename: file_name,
      content_type: content_type
    )
    file
  end

  describe "associations" do
    it { should belong_to(:workspace) }
    it { should belong_to(:user) }
    it { should belong_to(:folder) }
  end

  describe "validations" do
    it { should validate_presence_of(:file_name) }

    it "requires an attached file" do
      file = workspace.stored_files.build(file_name: "x.pdf", user: user, folder: folder)
      expect(file).not_to be_valid
      expect(file.errors[:uploaded_file]).to include("must be attached")
    end

    it "rejects disallowed content types" do
      file = build_file(file_name: "evil.exe", content_type: "application/x-msdownload")
      expect(file).not_to be_valid
      expect(file.errors[:uploaded_file].first).to include("must be a PDF, image, document, or spreadsheet")
    end

    it "rejects files larger than the maximum size" do
      file = build_file(file_name: "huge.pdf", byte_size: StoredFile::MAX_FILE_SIZE + 1)
      expect(file).not_to be_valid
      expect(file.errors[:uploaded_file].first).to include("MB or less")
    end
  end

  describe "scopes" do
    it "returns files in alphabetical order" do
      zebra = build_file(file_name: "zebra.pdf").tap(&:save!)
      apple = build_file(file_name: "apple.pdf").tap(&:save!)
      expect(StoredFile.by_name).to eq([ apple, zebra ])
    end

    it "searches files by name" do
      invoice = build_file(file_name: "invoice.pdf").tap(&:save!)
      photo = build_file(file_name: "photo.jpg", content_type: "image/jpeg").tap(&:save!)
      expect(StoredFile.search("invoice")).to include(invoice)
      expect(StoredFile.search("invoice")).not_to include(photo)
    end
  end
end
