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
  end

  context "as an admin" do
    let(:user) { User.create!(email: "admin@example.com", password: "password") }
    let(:membership) { Membership.create!(user: user, workspace: workspace, role: "admin") }

    it_behaves_like "can view folders"
    it_behaves_like "can manage folders"
  end

  context "as a member" do
    let(:user) { User.create!(email: "member@example.com", password: "password") }
    let(:membership) { Membership.create!(user: user, workspace: workspace, role: "member") }

    it_behaves_like "can view folders"
    it_behaves_like "can manage folders"
  end

  context "as a viewer" do
    let(:user) { User.create!(email: "viewer@example.com", password: "password") }
    let(:membership) { Membership.create!(user: user, workspace: workspace, role: "viewer") }

    it_behaves_like "can view folders"
    it_behaves_like "cannot manage folders"
  end

  context "as a non-member (different workspace)" do
    let(:user) { User.create!(email: "stranger@example.com", password: "password") }
    let(:membership) { nil }

    it { expect(policy.index?).to be false }
    it { expect(policy.show?).to be false }
    it_behaves_like "cannot manage folders"
  end
end
