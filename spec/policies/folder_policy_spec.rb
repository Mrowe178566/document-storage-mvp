require "rails_helper"

RSpec.describe FolderPolicy do
  subject(:policy) { described_class.new(context, folder) }

  let(:setup)        { create_owner_with_workspace(email: "owner@example.com") }
  let(:owner)        { setup[0] }
  let(:workspace)    { setup[1] }
  let(:folder)       { workspace.folders.create!(name: "Plans", user: owner) }
  let(:context)      { ApplicationController::PunditContext.new(user, membership) }

  shared_examples "can view folders" do
    it { expect(policy.index?).to be true }
    it { expect(policy.show?).to be true }
  end

  shared_examples "can manage folders" do
    it { expect(policy.create?).to be true }
    it { expect(policy.update?).to be true }
    it { expect(policy.destroy?).to be true }
  end

  shared_examples "cannot manage folders" do
    it { expect(policy.create?).to be false }
    it { expect(policy.update?).to be false }
    it { expect(policy.destroy?).to be false }
  end

  context "as an owner" do
    let(:user) { owner }
    let(:membership) { owner.membership_for(workspace) }

    it_behaves_like "can view folders"
    it_behaves_like "can manage folders"

    it "can manage permissions" do
      expect(policy.manage_permissions?).to be true
    end
  end

  context "as an admin" do
    let(:user) { User.create!(email: "admin@example.com", password: "password") }
    let(:membership) { Membership.create!(user: user, workspace: workspace, role: "admin") }

    it_behaves_like "can view folders"
    it_behaves_like "can manage folders"

    it "can manage permissions" do
      expect(policy.manage_permissions?).to be true
    end
  end

  context "as a member" do
    let(:user) { User.create!(email: "member@example.com", password: "password") }
    let(:membership) { Membership.create!(user: user, workspace: workspace, role: "member") }

    it_behaves_like "can view folders"
    it_behaves_like "can manage folders"

    it "cannot manage permissions" do
      expect(policy.manage_permissions?).to be false
    end
  end

  context "as a viewer" do
    let(:user) { User.create!(email: "viewer@example.com", password: "password") }
    let(:membership) { Membership.create!(user: user, workspace: workspace, role: "viewer") }

    it_behaves_like "can view folders"
    it_behaves_like "cannot manage folders"

    it "cannot manage permissions" do
      expect(policy.manage_permissions?).to be false
    end
  end

  context "as a non-member (different workspace)" do
    let(:user) { User.create!(email: "stranger@example.com", password: "password") }
    let(:membership) { nil }

    it { expect(policy.index?).to be false }
    it { expect(policy.show?).to be false }
    it_behaves_like "cannot manage folders"
  end

  # ───────────────────────────────────────────────────────────
  # Restricted-folder visibility (per-user permissions)
  # ───────────────────────────────────────────────────────────
  describe "restricted folders" do
    let(:admin)             { create_member(workspace, email: "admin@example.com", role: "admin") }
    let(:admin_membership)  { admin.membership_for(workspace) }
    let(:member)            { create_member(workspace, email: "m@example.com", role: "member") }
    let(:member_membership) { member.membership_for(workspace) }
    let(:viewer)            { create_member(workspace, email: "v@example.com", role: "viewer") }
    let(:viewer_membership) { viewer.membership_for(workspace) }
    let!(:restricted_folder) {
      f = workspace.folders.create!(name: "Restricted", user: owner)
      f.folder_permissions.create!(user: member)
      f
    }

    it "admin can see restricted folder even without grant" do
      ctx = ApplicationController::PunditContext.new(admin, admin_membership)
      expect(FolderPolicy.new(ctx, restricted_folder).show?).to be true
    end

    it "member with explicit grant can see restricted folder" do
      ctx = ApplicationController::PunditContext.new(member, member_membership)
      expect(FolderPolicy.new(ctx, restricted_folder).show?).to be true
    end

    it "viewer without grant cannot see restricted folder" do
      ctx = ApplicationController::PunditContext.new(viewer, viewer_membership)
      expect(FolderPolicy.new(ctx, restricted_folder).show?).to be false
    end
  end

  # ───────────────────────────────────────────────────────────
  # Scope behavior on a mix of public + restricted folders
  # ───────────────────────────────────────────────────────────
  describe "Scope" do
    let!(:public_folder)     { workspace.folders.create!(name: "Public", user: owner) }
    let!(:restricted_folder) {
      f = workspace.folders.create!(name: "Restricted", user: owner)
      f.folder_permissions.create!(user: member)
      f
    }
    let(:admin)             { create_member(workspace, email: "admin@example.com", role: "admin") }
    let(:admin_membership)  { admin.membership_for(workspace) }
    let(:member)            { create_member(workspace, email: "m@example.com", role: "member") }
    let(:member_membership) { member.membership_for(workspace) }
    let(:viewer)            { create_member(workspace, email: "v@example.com", role: "viewer") }
    let(:viewer_membership) { viewer.membership_for(workspace) }

    def scope_for(user, membership)
      ctx = ApplicationController::PunditContext.new(user, membership)
      FolderPolicy::Scope.new(ctx, Folder).resolve
    end

    it "returns all folders for admin" do
      expect(scope_for(admin, admin_membership)).to include(public_folder, restricted_folder)
    end

    it "returns public + granted folders for member with grant" do
      expect(scope_for(member, member_membership)).to include(public_folder, restricted_folder)
    end

    it "returns only public folders for viewer without grant" do
      result = scope_for(viewer, viewer_membership)
      expect(result).to include(public_folder)
      expect(result).not_to include(restricted_folder)
    end

    it "returns nothing for a non-member" do
      stranger = User.create!(email: "stranger@example.com", password: "password")
      expect(scope_for(stranger, nil)).to be_empty
    end
  end
end
