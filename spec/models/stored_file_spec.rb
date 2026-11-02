require "rails_helper"

RSpec.describe StoredFile, type: :model do
  let(:user_workspace) { create_owner_with_workspace }
  let(:user) { user_workspace[0] }
  let(:workspace) { user_workspace[1] }
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
    it { should belong_to(:document_type).optional }
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

  describe "document type" do
    let(:insurance) do
      workspace.document_types.create!(
        name: "Insurance certificate", expires: true, valid_for_months: 12, remind_days_before: 30
      )
    end

    it "is optional, so existing uploads keep working" do
      expect(build_file(file_name: "plain.pdf")).to be_valid
    end

    it "can be set along with an expiry date" do
      file = build_file(file_name: "coi.pdf")
      file.document_type = insurance
      file.expires_on = Date.new(2027, 11, 2)
      file.save!
      expect(file.reload).to have_attributes(document_type: insurance, expires_on: Date.new(2027, 11, 2))
    end

    it "must belong to the same workspace as the file" do
      _, other_workspace = create_owner_with_workspace(workspace_name: "Other")
      foreign_type = other_workspace.document_types.create!(name: "Insurance certificate")

      file = build_file(file_name: "coi.pdf")
      file.document_type = foreign_type
      expect(file).not_to be_valid
      expect(file.errors[:document_type]).to include("must belong to this workspace")
    end

    it "is cleared, not deleted, when the type is removed" do
      file = build_file(file_name: "coi.pdf")
      file.document_type = insurance
      file.save!

      insurance.destroy!
      expect(file.reload.document_type).to be_nil
    end

    it "keeps the file's expiry date when the type's settings change later" do
      file = build_file(file_name: "coi.pdf")
      file.document_type = insurance
      file.expires_on = Date.new(2027, 11, 2)
      file.save!

      insurance.update!(valid_for_months: 24)
      expect(file.reload.expires_on).to eq(Date.new(2027, 11, 2))
    end
  end
end
