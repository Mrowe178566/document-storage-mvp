require "rails_helper"

RSpec.describe Membership, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:workspace) }
  end

  describe "ROLES constant" do
    it "includes viewer, member, admin, owner in ascending order" do
      expect(Membership::ROLES).to eq(%w[viewer member admin owner])
    end
  end

  describe "validations" do
    it "accepts viewer as a role" do
      _, workspace = create_owner_with_workspace
      user = User.create!(email: "viewer@example.com", password: "password")
      m = Membership.new(user: user, workspace: workspace, role: "viewer")
      expect(m).to be_valid
    end

    it "rejects an unknown role" do
      _, workspace = create_owner_with_workspace
      user = User.create!(email: "user@example.com", password: "password")
      bad = Membership.new(user: user, workspace: workspace, role: "boss")
      expect(bad).not_to be_valid
    end

    it "blocks duplicate user/workspace pairs" do
      user, workspace = create_owner_with_workspace
      duplicate = Membership.new(user: user, workspace: workspace, role: "member")
      expect(duplicate).not_to be_valid
    end

    it "blocks adding a second owner to a workspace" do
      _, workspace = create_owner_with_workspace
      second_user = User.create!(email: "second@example.com", password: "password")
      bad = Membership.new(user: second_user, workspace: workspace, role: "owner")
      expect(bad).not_to be_valid
      expect(bad.errors[:role].first).to include("already has an owner")
    end
  end

  describe "predicates" do
    let(:workspace) { Workspace.create!(name: "Test") }
    let(:user) { User.create!(email: "user@example.com", password: "password") }

    it "owner? admin? member? viewer? reflect role" do
      m = Membership.new(role: "owner", workspace: workspace, user: user)
      expect(m.owner?).to be(true)
      expect(m.admin?).to be(true)
      expect(m.member?).to be(false)
      expect(m.viewer?).to be(false)

      m.role = "admin"
      expect(m.owner?).to be(false)
      expect(m.admin?).to be(true)
      expect(m.member?).to be(false)
      expect(m.viewer?).to be(false)

      m.role = "member"
      expect(m.owner?).to be(false)
      expect(m.admin?).to be(false)
      expect(m.member?).to be(true)
      expect(m.viewer?).to be(false)

      m.role = "viewer"
      expect(m.owner?).to be(false)
      expect(m.admin?).to be(false)
      expect(m.member?).to be(false)
      expect(m.viewer?).to be(true)
    end

    it "can_edit? returns true for everyone except viewer" do
      expect(Membership.new(role: "owner").can_edit?).to be true
      expect(Membership.new(role: "admin").can_edit?).to be true
      expect(Membership.new(role: "member").can_edit?).to be true
      expect(Membership.new(role: "viewer").can_edit?).to be false
    end
  end
end
