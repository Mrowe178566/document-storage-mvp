require "rails_helper"

RSpec.describe StoredFilePolicy do
  subject(:policy) { described_class.new(context, stored_file) }

  let(:setup)        { create_owner_with_workspace(email: "owner@example.com") }
  let(:owner)        { setup[0] }
  let(:workspace)    { setup[1] }
  let(:folder)       { workspace.folders.create!(name: "Plans", user: owner) }
  let(:stored_file)  { StoredFile.new(workspace: workspace, folder: folder, user: owner) }
  let(:context)      { ApplicationController::PunditContext.new(user, membership) }

  describe "viewer permissions" do
    let(:user) { User.create!(email: "viewer@example.com", password: "password") }
    let(:membership) { Membership.create!(user: user, workspace: workspace, role: "viewer") }

    it "can view and download files" do
      expect(policy.show?).to be true
      expect(policy.download?).to be true
    end

    it "cannot upload, delete, or bulk-delete" do
      expect(policy.create?).to be false
      expect(policy.destroy?).to be false
      expect(policy.bulk_delete?).to be false
    end
  end

  describe "member permissions" do
    let(:user) { User.create!(email: "member@example.com", password: "password") }
    let(:membership) { Membership.create!(user: user, workspace: workspace, role: "member") }

    it "can do everything except admin-level actions" do
      expect(policy.show?).to be true
      expect(policy.download?).to be true
      expect(policy.create?).to be true
      expect(policy.destroy?).to be true
      expect(policy.bulk_delete?).to be true
    end
  end

  describe "files in a restricted folder" do
    let(:folder) do
      workspace.folders.create!(name: "HR only", user: owner).tap do |f|
        f.folder_permissions.create!(user: owner)
      end
    end

    context "as a member who wasn't granted access" do
      let(:user) { User.create!(email: "member@example.com", password: "password") }
      let(:membership) { Membership.create!(user: user, workspace: workspace, role: "member") }

      it "can't view, download, upload, or delete" do
        expect(policy.show?).to be false
        expect(policy.download?).to be false
        expect(policy.create?).to be false
        expect(policy.destroy?).to be false
      end
    end

    context "as a member who was granted access" do
      let(:user) { User.create!(email: "granted@example.com", password: "password") }
      let(:membership) { Membership.create!(user: user, workspace: workspace, role: "member") }

      before { folder.folder_permissions.create!(user: user) }

      it "can view, download, upload, and delete" do
        expect(policy.show?).to be true
        expect(policy.download?).to be true
        expect(policy.create?).to be true
        expect(policy.destroy?).to be true
      end
    end
  end

  describe "a file in another workspace" do
    let(:user)       { create_owner_with_workspace(email: "other@example.com")[0] }
    let(:membership) { user.memberships.first }

    it "is off limits, even to that other workspace's owner" do
      expect(policy.show?).to be false
      expect(policy.download?).to be false
      expect(policy.destroy?).to be false
    end
  end
end
