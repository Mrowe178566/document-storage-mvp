require "rails_helper"

RSpec.describe Invitation, type: :model do
  let(:setup) { create_owner_with_workspace(email: "admin@example.com") }
  let(:admin) { setup[0] }
  let(:workspace) { setup[1] }

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
    it "creates a member-role membership for the user and marks the invitation accepted" do
      invitation = workspace.invitations.create!(email: "new@example.com", invited_by: admin)
      user = User.create!(email: "new@example.com", password: "password")

      expect { invitation.accept!(user) }.to change { Membership.count }.by(1)

      expect(user.workspaces.reload).to include(workspace)
      expect(user.role_in(workspace)).to eq("member")
      expect(invitation.reload).to be_accepted
    end

    it "is idempotent if the user is already a member" do
      invitation = workspace.invitations.create!(email: "existing@example.com", invited_by: admin)
      existing = create_member(workspace, email: "existing@example.com", role: "member")

      expect { invitation.accept!(existing) }.not_to change { Membership.count }
      expect(invitation.reload).to be_accepted
    end
  end
end
