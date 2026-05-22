require "rails_helper"

RSpec.describe WorkspacePolicy do
  subject(:policy) { described_class.new(context, workspace) }

  let(:setup)     { create_owner_with_workspace(email: "owner@example.com") }
  let(:owner)     { setup[0] }
  let(:workspace) { setup[1] }
  let(:context)   { ApplicationController::PunditContext.new(user, membership) }

  describe "viewer permissions" do
    let(:user) { User.create!(email: "viewer@example.com", password: "password") }
    let(:membership) { Membership.create!(user: user, workspace: workspace, role: "viewer") }

    it "can see the workspace, team, recent activity, dashboard" do
      expect(policy.show?).to be true
      expect(policy.team?).to be true
      expect(policy.recent?).to be true
      expect(policy.dashboard?).to be true
    end

    it "cannot manage the workspace or run bootstrap" do
      expect(policy.update?).to be false
      expect(policy.bootstrap?).to be false
      expect(policy.manage?).to be false
    end
  end

  describe "admin permissions" do
    let(:user) { User.create!(email: "admin@example.com", password: "password") }
    let(:membership) { Membership.create!(user: user, workspace: workspace, role: "admin") }

    it "can do everything view-related" do
      expect(policy.show?).to be true
      expect(policy.team?).to be true
    end

    it "can also manage and bootstrap" do
      expect(policy.update?).to be true
      expect(policy.bootstrap?).to be true
    end
  end

  describe "create permissions" do
    let(:user) { User.create!(email: "anyone@example.com", password: "password") }
    let(:membership) { nil }

    it "any signed-in user can create a new workspace" do
      expect(policy.create?).to be true
    end
  end
end
