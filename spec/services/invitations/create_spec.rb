require "rails_helper"

RSpec.describe Invitations::Create do
  let(:setup)      { create_owner_with_workspace(email: "admin@example.com") }
  let(:admin)      { setup[0] }
  let(:workspace)  { setup[1] }

  before { ActionMailer::Base.deliveries.clear }

  describe ".call" do
    it "creates an invitation and dispatches the mailer" do
      result = nil
      perform_enqueued_jobs do
        result = described_class.call(
          workspace: workspace,
          invited_by: admin,
          email: "new@example.com",
          role: "member"
        )
      end

      expect(result).to be_success
      expect(result.invitation).to be_persisted
      expect(result.invitation.email).to eq("new@example.com")
      expect(result.invitation.role).to eq("member")
      expect(ActionMailer::Base.deliveries.last.to).to eq([ "new@example.com" ])
    end

    it "defaults role to member when not provided" do
      result = described_class.call(workspace: workspace, invited_by: admin, email: "x@y.com")
      expect(result.invitation.role).to eq("member")
    end

    it "supports inviting as viewer" do
      result = described_class.call(workspace: workspace, invited_by: admin, email: "v@y.com", role: "viewer")
      expect(result.invitation.role).to eq("viewer")
    end

    it "rejects blank email" do
      result = described_class.call(workspace: workspace, invited_by: admin, email: "")
      expect(result).not_to be_success
      expect(result.error).to match(/can't be blank/i)
    end

    it "rejects inviting someone who's already a member" do
      member = create_member(workspace, email: "already@example.com", role: "member")

      result = described_class.call(workspace: workspace, invited_by: admin, email: member.email)
      expect(result).not_to be_success
      expect(result.error).to match(/already a member/i)
    end

    it "downcases and trims the email" do
      result = described_class.call(workspace: workspace, invited_by: admin, email: "  MIXED@Case.COM  ")
      expect(result.invitation.email).to eq("mixed@case.com")
    end
  end
end
