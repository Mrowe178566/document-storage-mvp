require "rails_helper"

RSpec.describe Folder, type: :model do
  describe "associations" do
    it { should belong_to(:workspace) }
    it { should belong_to(:user) }
    it { should have_many(:stored_files).dependent(:destroy) }
    it { should have_many(:folder_permissions).dependent(:destroy) }
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

  describe "visibility" do
    let(:setup)     { create_owner_with_workspace(email: "owner@example.com") }
    let(:owner)     { setup[0] }
    let(:workspace) { setup[1] }
    let(:owner_membership)  { owner.membership_for(workspace) }
    let(:admin)             { create_member(workspace, email: "admin@example.com", role: "admin") }
    let(:admin_membership)  { admin.membership_for(workspace) }
    let(:member)            { create_member(workspace, email: "member@example.com", role: "member") }
    let(:member_membership) { member.membership_for(workspace) }
    let(:viewer)            { create_member(workspace, email: "viewer@example.com", role: "viewer") }
    let(:viewer_membership) { viewer.membership_for(workspace) }
    let(:folder)            { workspace.folders.create!(name: "Quality Control", user: owner) }

    describe "#restricted?" do
      it "is false on a brand-new folder" do
        expect(folder.restricted?).to be false
      end

      it "is true once a folder_permission is added" do
        folder.folder_permissions.create!(user: member)
        expect(folder.reload.restricted?).to be true
      end
    end

    describe "#accessible_by?" do
      context "on an unrestricted (public) folder" do
        it "is accessible by any workspace member, including viewers" do
          expect(folder.accessible_by?(owner,  membership: owner_membership)).to  be true
          expect(folder.accessible_by?(admin,  membership: admin_membership)).to  be true
          expect(folder.accessible_by?(member, membership: member_membership)).to be true
          expect(folder.accessible_by?(viewer, membership: viewer_membership)).to be true
        end
      end

      context "on a restricted folder" do
        before { folder.folder_permissions.create!(user: member) }

        it "is accessible by admins regardless of explicit grant" do
          expect(folder.accessible_by?(owner, membership: owner_membership)).to be true
          expect(folder.accessible_by?(admin, membership: admin_membership)).to be true
        end

        it "is accessible by a non-admin who's explicitly granted" do
          expect(folder.accessible_by?(member, membership: member_membership)).to be true
        end

        it "is NOT accessible by a viewer without explicit grant" do
          expect(folder.accessible_by?(viewer, membership: viewer_membership)).to be false
        end

        it "becomes accessible to viewer once they're granted" do
          folder.folder_permissions.create!(user: viewer)
          expect(folder.reload.accessible_by?(viewer, membership: viewer_membership)).to be true
        end
      end
    end
  end
end
