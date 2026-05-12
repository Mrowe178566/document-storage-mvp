require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it { should belong_to(:workspace) }
    it { should have_many(:folders).dependent(:destroy) }
    it { should have_many(:stored_files).dependent(:destroy) }
    it { should have_many(:sent_invitations).class_name("Invitation").with_foreign_key(:invited_by_id).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:email) }
  end

  describe "signup" do
    it "automatically creates a workspace and makes the new user its admin" do
      user = User.create!(email: "founder@example.com", password: "password")
      expect(user.workspace).to be_present
      expect(user.workspace.name).to eq("Founder's Workspace")
      expect(user.role).to eq("admin")
    end

    it "does not create a workspace when one is already assigned" do
      workspace = Workspace.create!(name: "Existing", slug: SecureRandom.hex(4))
      user = User.create!(email: "joiner@example.com", password: "password", workspace: workspace, role: "member")
      expect(user.workspace).to eq(workspace)
      expect(user.role).to eq("member")
    end
  end
end
