require "rails_helper"

RSpec.describe Workspace, type: :model do
  describe "associations" do
    it { should have_many(:users).dependent(:destroy) }
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

  describe "#admins / #members" do
    it "partitions users by role" do
      workspace = Workspace.create!(name: "Test")
      admin = User.create!(email: "admin@example.com", password: "password", workspace: workspace, role: "admin")
      member = User.create!(email: "member@example.com", password: "password", workspace: workspace, role: "member")
      expect(workspace.admins).to contain_exactly(admin)
      expect(workspace.members).to contain_exactly(member)
    end
  end
end
