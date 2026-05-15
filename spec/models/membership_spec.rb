require "rails_helper"

RSpec.describe Membership, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:workspace) }
  end

  describe "validations" do
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

    it "owner? admin? member? reflect role" do
      m = Membership.new(role: "owner", workspace: workspace, user: user)
      expect(m.owner?).to be(true)
      expect(m.admin?).to be(true)
      expect(m.member?).to be(false)

      m.role = "admin"
      expect(m.owner?).to be(false)
      expect(m.admin?).to be(true)
      expect(m.member?).to be(false)

      m.role = "member"
      expect(m.owner?).to be(false)
      expect(m.admin?).to be(false)
      expect(m.member?).to be(true)
    end
  end
end
