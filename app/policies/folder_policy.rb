class FolderPolicy < ApplicationPolicy
  # Anyone in the workspace (viewer included) can browse the folder list and
  # open a folder to see its contents.
  def index?; any_member?; end
  def show?;  any_member?; end

  # Member, admin, owner can create/rename/delete folders. Viewer cannot.
  def create?;  can_edit?; end
  def new?;     create?;   end
  def update?;  can_edit?; end
  def edit?;    update?;   end
  def destroy?; can_edit?; end

  class Scope < Scope
    def resolve
      return scope.none unless membership
      scope.where(workspace_id: membership.workspace_id)
    end
  end
end
