require "rails_helper"

RSpec.describe Folder, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
    it { should have_many(:stored_files).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
  end

  describe "scopes" do
    it "returns folders in descending order of creation" do
      user = User.create!(email: "test@example.com", password: "password")
      older = user.folders.create!(name: "Older Folder")
      newer = user.folders.create!(name: "Newer Folder")
      expect(Folder.recent).to eq([ newer, older ])
    end
  end
end
