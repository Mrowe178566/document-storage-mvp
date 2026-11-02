require "rails_helper"

RSpec.describe DocumentTypePolicy do
  subject(:policy) { described_class.new(context, document_type) }

  let(:setup)         { create_owner_with_workspace(email: "owner@example.com") }
  let(:owner)         { setup[0] }
  let(:workspace)     { setup[1] }
  let(:document_type) { workspace.document_types.create!(name: "Tax form") }
  let(:context)       { ApplicationController::PunditContext.new(user, membership) }
  let(:user)          { create_member(workspace, role: role) }
  let(:membership)    { user.membership_for(workspace) }

  # Everyone in the workspace needs to see the list so they can pick a type
  # when they upload. Only owners and admins change the list.
  { "viewer" => false, "member" => false, "admin" => true, "owner" => true }.each do |role_name, can_manage|
    context "as a #{role_name}" do
      let(:role) { role_name }
      let(:user) { role_name == "owner" ? owner : create_member(workspace, role: role_name) }

      it "can see the document types" do
        expect(policy.index?).to be true
        expect(policy.show?).to be true
      end

      it "#{can_manage ? 'can' : 'cannot'} add, edit, or remove document types" do
        expect(policy.create?).to be can_manage
        expect(policy.update?).to be can_manage
        expect(policy.destroy?).to be can_manage
      end
    end
  end

  context "with no membership in the workspace" do
    let(:user)       { User.create!(email: "outsider@example.com", password: "password") }
    let(:membership) { nil }

    it "allows nothing" do
      expect(policy.index?).to be false
      expect(policy.show?).to be false
      expect(policy.create?).to be false
    end
  end

  context "with a document type from another workspace" do
    let(:role) { "owner" }
    let(:user) { owner }
    let(:document_type) do
      _, other = create_owner_with_workspace(workspace_name: "Other")
      other.document_types.create!(name: "Tax form")
    end

    it "allows nothing, even for the owner of this workspace" do
      expect(policy.show?).to be false
      expect(policy.update?).to be false
      expect(policy.destroy?).to be false
    end
  end

  describe "Scope" do
    let(:role) { "viewer" }

    it "only returns this workspace's document types" do
      mine = document_type
      _, other = create_owner_with_workspace(workspace_name: "Other")
      other.document_types.create!(name: "Not mine")

      resolved = DocumentTypePolicy::Scope.new(context, DocumentType).resolve
      expect(resolved).to contain_exactly(mine)
    end

    it "returns nothing without a membership" do
      document_type
      outsider_context = ApplicationController::PunditContext.new(user, nil)
      expect(DocumentTypePolicy::Scope.new(outsider_context, DocumentType).resolve).to be_empty
    end
  end
end
