class DocumentTypePolicy < ApplicationPolicy
  # Everyone in the workspace, viewers included, can see the list. Uploaders
  # need it to pick a type, and viewers need it to read a document's status.
  def index?; any_member?; end
  def show?;  same_workspace?; end

  # Only owners and admins change the list, because a type's settings decide
  # expiry dates and approvals for the whole workspace.
  def create?;  admin?; end
  def update?;  admin? && same_workspace?; end
  def destroy?; admin? && same_workspace?; end

  class Scope < Scope
    def resolve
      return scope.none unless membership
      scope.where(workspace_id: membership.workspace_id)
    end
  end

  private

  # Checks the workspace too, so a type from another workspace is never
  # allowed even if a controller forgets to scope its lookup.
  def same_workspace?
    any_member? && record.workspace_id == membership.workspace_id
  end
end
