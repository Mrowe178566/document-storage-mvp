require "rails_helper"

RSpec.describe StoredFile, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:folder) }
  end

  describe "validations" do
    it { should validate_presence_of(:file_name) }
  end

  describe "scopes" do
    it "returns files in alphabetical order" do
      user = User.create!(email: "test@example.com", password: "password")
      folder = user.folders.create!(name: "Test Folder")
      zebra = folder.stored_files.create!(file_name: "zebra.pdf", user: user)
      apple = folder.stored_files.create!(file_name: "apple.pdf", user: user)
      expect(StoredFile.by_name).to eq([apple, zebra])
    end

    it "searches files by name" do
      user = User.create!(email: "test@example.com", password: "password")
      folder = user.folders.create!(name: "Test Folder")
      invoice = folder.stored_files.create!(file_name: "invoice.pdf", user: user)
      photo = folder.stored_files.create!(file_name: "photo.jpg", user: user)
      expect(StoredFile.search("invoice")).to include(invoice)
      expect(StoredFile.search("invoice")).not_to include(photo)
    end
  end
end
