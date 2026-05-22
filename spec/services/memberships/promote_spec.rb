require "rails_helper"

RSpec.describe Memberships::Promote do
  let(:setup)      { create_owner_with_workspace(email: "owner@example.com") }
  let(:owner)      { setup[0] }
  let(:workspace)  { setup[1] }

  describe ".call" do
    it "promotes a member to admin" do
      member_user = create_member(workspace, email: "m@example.com", role: "member")
      membership  = member_user.membership_for(workspace)

      result = described_class.call(membership: membership)

      expect(result).to be_success
      expect(membership.reload.role).to eq("admin")
    end

    it "promotes a viewer to admin in one step" do
      viewer_user = create_member(workspace, email: "v@example.com", role: "viewer")
      membership  = viewer_user.membership_for(workspace)

      result = described_class.call(membership: membership)

      expect(result).to be_success
      expect(membership.reload.role).to eq("admin")
    end

    it "fails if the membership is already an admin" do
      admin_user = create_member(workspace, email: "a@example.com", role: "admin")
      membership = admin_user.membership_for(workspace)

      result = described_class.call(membership: membership)

      expect(result).not_to be_success
      expect(result.error).to match(/already an admin/i)
    end

    it "fails if the membership is the owner" do
      owner_membership = owner.membership_for(workspace)

      result = described_class.call(membership: owner_membership)

      expect(result).not_to be_success
      expect(result.error).to match(/owner/i)
    end
  end
end
