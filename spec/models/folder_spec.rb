require "rails_helper"

RSpec.describe Folder, type: :model do
  describe "associations" do
    it { should belong_to(:workspace) }
    it { should belong_to(:user) }
    it { should have_many(:stored_files).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }
  end

  describe "scopes" do
    it "returns folders in descending order of creation" do
      user, workspace = create_owner_with_workspace
      older = workspace.folders.create!(name: "Older Folder", user: user)
      newer = workspace.folders.create!(name: "Newer Folder", user: user)
      expect(Folder.recent).to eq([ newer, older ])
    end
  end
end
