require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it { should have_many(:memberships).dependent(:destroy) }
    it { should have_many(:workspaces).through(:memberships) }
    it { should have_many(:folders).dependent(:destroy) }
    it { should have_many(:stored_files).dependent(:destroy) }
    it { should have_many(:sent_invitations).class_name("Invitation").with_foreign_key(:invited_by_id).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:email) }
  end

  describe "#membership_for" do
    it "returns the membership for a workspace the user belongs to" do
      user, workspace = create_owner_with_workspace
      expect(user.membership_for(workspace)).to be_present
      expect(user.membership_for(workspace).role).to eq("owner")
    end

    it "returns nil for a workspace the user doesn't belong to" do
      user, _ = create_owner_with_workspace
      other = Workspace.create!(name: "Other")
      expect(user.membership_for(other)).to be_nil
    end
  end

  describe "role predicates" do
    let(:workspace) { Workspace.create!(name: "Test") }
    let(:owner)   { create_member(workspace, email: "o@example.com", role: "owner") }
    let(:admin)   { create_member(workspace, email: "a@example.com", role: "admin") }
    let(:member)  { create_member(workspace, email: "m@example.com", role: "member") }
    let(:outsider) { User.create!(email: "x@example.com", password: "password") }

    it "owner_of? is true only for the owner" do
      expect(owner.owner_of?(workspace)).to be(true)
      expect(admin.owner_of?(workspace)).to be(false)
      expect(member.owner_of?(workspace)).to be(false)
      expect(outsider.owner_of?(workspace)).to be(false)
    end

    it "admin_of? includes both owner and admin" do
      expect(owner.admin_of?(workspace)).to be(true)
      expect(admin.admin_of?(workspace)).to be(true)
      expect(member.admin_of?(workspace)).to be(false)
      expect(outsider.admin_of?(workspace)).to be(false)
    end

    it "member_of? is true for any membership role" do
      expect(owner.member_of?(workspace)).to be(true)
      expect(admin.member_of?(workspace)).to be(true)
      expect(member.member_of?(workspace)).to be(true)
      expect(outsider.member_of?(workspace)).to be(false)
    end
  end
end
