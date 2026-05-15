require "rails_helper"

RSpec.describe Workspace, type: :model do
  describe "associations" do
    it { should have_many(:memberships).dependent(:destroy) }
    it { should have_many(:users).through(:memberships) }
    it { should have_many(:folders).dependent(:destroy) }
    it { should have_many(:stored_files).dependent(:destroy) }
    it { should have_many(:invitations).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:name) }

    it "auto-generates a unique slug on create" do
      a = Workspace.create!(name: "One")
      b = Workspace.create!(name: "Two")
      expect(a.slug).to be_present
      expect(b.slug).to be_present
      expect(a.slug).not_to eq(b.slug)
    end
  end

  describe "#owner / #admins / #members" do
    let!(:workspace) { Workspace.create!(name: "Test") }
    let!(:owner)  { create_member(workspace, email: "owner@example.com", role: "owner") }
    let!(:admin)  { create_member(workspace, email: "admin@example.com", role: "admin") }
    let!(:member) { create_member(workspace, email: "member@example.com", role: "member") }

    it "#owner returns the user with role=owner" do
      expect(workspace.owner).to eq(owner)
    end

    it "#admins returns owners and admins" do
      expect(workspace.admins).to contain_exactly(owner, admin)
    end

    it "#members returns only role=member users" do
      expect(workspace.members).to contain_exactly(member)
    end
  end
end
