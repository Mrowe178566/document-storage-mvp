require "rails_helper"

RSpec.describe Invitation, type: :model do
  let(:admin) { User.create!(email: "admin@example.com", password: "password") }
  let(:workspace) { admin.workspace }

  describe "associations" do
    it { should belong_to(:workspace) }
    it { should belong_to(:invited_by).class_name("User") }
  end

  describe "validations" do
    it "requires a valid email" do
      invitation = workspace.invitations.build(email: "not-an-email", invited_by: admin)
      expect(invitation).not_to be_valid
      expect(invitation.errors[:email]).to be_present
    end
  end

  describe "creation" do
    it "auto-generates a token and an expiry" do
      invitation = workspace.invitations.create!(email: "new@example.com", invited_by: admin)
      expect(invitation.token).to be_present
      expect(invitation.expires_at).to be > Time.current
    end
  end

  describe "#usable?" do
    it "is true for fresh, unaccepted invitations" do
      invitation = workspace.invitations.create!(email: "new@example.com", invited_by: admin)
      expect(invitation).to be_usable
    end

    it "is false once accepted" do
      invitation = workspace.invitations.create!(email: "new@example.com", invited_by: admin)
      invitation.update!(accepted_at: Time.current)
      expect(invitation).not_to be_usable
    end

    it "is false once expired" do
      invitation = workspace.invitations.create!(email: "new@example.com", invited_by: admin)
      invitation.update!(expires_at: 1.day.ago)
      expect(invitation).not_to be_usable
    end
  end

  describe "#accept!" do
    it "assigns the user to the workspace as a member and marks the invitation accepted" do
      invitation = workspace.invitations.create!(email: "new@example.com", invited_by: admin)
      other_workspace = Workspace.create!(name: "Other")
      user = User.create!(email: "new@example.com", password: "password", workspace: other_workspace, role: "member")

      invitation.accept!(user)

      expect(user.reload.workspace).to eq(workspace)
      expect(user.role).to eq("member")
      expect(invitation.reload).to be_accepted
    end
  end
end
