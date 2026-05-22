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
end
