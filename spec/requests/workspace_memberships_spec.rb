require "rails_helper"

RSpec.describe "Workspace memberships", type: :request do
  let(:owner_setup) { create_owner_with_workspace(email: "owner@example.com") }
  let(:owner) { owner_setup[0] }
  let(:workspace) { owner_setup[1] }
  let(:admin) { create_member(workspace, email: "admin@example.com", role: "admin") }
  let(:member) { create_member(workspace, email: "member@example.com", role: "member") }

  describe "promote (member → admin)" do
    it "lets an admin promote a member to admin" do
      sign_in admin
      m = member.membership_for(workspace)

      patch workspace_membership_path(m, role: "admin")

      expect(m.reload.role).to eq("admin")
      expect(response).to redirect_to(workspace_path)
    end

    it "blocks a non-admin from promoting" do
      sign_in member
      target = create_member(workspace, email: "third@example.com", role: "member").membership_for(workspace)

      patch workspace_membership_path(target, role: "admin")

      expect(target.reload.role).to eq("member")
    end
  end

  describe "demote (admin → member)" do
    it "demotes an admin to member" do
      sign_in owner
      m = admin.membership_for(workspace)

      patch workspace_membership_path(m, role: "member")

      expect(m.reload.role).to eq("member")
    end

    it "won't demote the owner" do
      sign_in owner
      m = owner.membership_for(workspace)

      patch workspace_membership_path(m, role: "member")

      expect(m.reload.role).to eq("owner")
    end
  end

  describe "transfer ownership" do
    it "owner promotes an admin to owner and is themselves demoted to admin" do
      sign_in owner
      a_membership = admin.membership_for(workspace)

      patch workspace_membership_path(a_membership, role: "owner")

      expect(a_membership.reload.role).to eq("owner")
      expect(owner.membership_for(workspace).reload.role).to eq("admin")
    end

    it "won't transfer to a non-admin member" do
      sign_in owner
      m = member.membership_for(workspace)

      patch workspace_membership_path(m, role: "owner")

      expect(m.reload.role).to eq("member")
      expect(owner.membership_for(workspace).reload.role).to eq("owner")
    end
  end

  describe "remove (admin removes someone)" do
    it "removes a member from the workspace" do
      sign_in admin
      m = member.membership_for(workspace)

      expect { delete workspace_membership_path(m) }.to change { Membership.count }.by(-1)
    end

    it "won't remove the owner" do
      sign_in admin
      m = owner.membership_for(workspace)

      expect { delete workspace_membership_path(m) }.not_to change { Membership.count }
    end
  end

  describe "self leave" do
    it "allows a member to leave when they have another workspace" do
      _, other_workspace = create_owner_with_workspace(workspace_name: "Other")
      Membership.create!(user: member, workspace: other_workspace, role: "member")

      sign_in member
      m = member.membership_for(workspace)

      expect { delete workspace_membership_path(m) }.to change { Membership.exists?(m.id) }.from(true).to(false)
    end

    it "blocks leaving the only workspace" do
      sign_in member
      m = member.membership_for(workspace)

      expect { delete workspace_membership_path(m) }.not_to change { Membership.count }
    end

    it "blocks the owner from leaving via self-leave" do
      sign_in owner
      m = owner.membership_for(workspace)

      expect { delete workspace_membership_path(m) }.not_to change { Membership.count }
    end
  end
end
