class StoredFilePolicy < ApplicationPolicy
  # Viewers CAN see and download files — that's the whole point of viewer.
  def show?;     any_member?; end
  def download?; any_member?; end

  # Only non-viewers can upload or delete.
  def create?;      can_edit?; end
  def destroy?;     can_edit?; end
  def bulk_delete?; can_edit?; end

  class Scope < Scope
    def resolve
      return scope.none unless membership
      scope.where(workspace_id: membership.workspace_id)
    end
  end
end
