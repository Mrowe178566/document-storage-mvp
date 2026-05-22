class FolderPolicy < ApplicationPolicy
  # Listing the folders index is allowed to anyone in the workspace —
  # what they actually SEE is filtered by Scope below.
  def index?; any_member?; end

  # Showing a specific folder respects per-folder permissions.
  # Admins always see everything; non-admins see unrestricted folders OR
  # ones they're explicitly granted on.
  def show?
    return false unless any_member?
    record.accessible_by?(user, membership: membership)
  end

  # Member, admin, owner can create/rename/delete folders. Viewer cannot.
  def create?;  can_edit?; end
  def new?;     create?;   end
  def update?;  can_edit? && show?; end
  def edit?;    update?;   end
  def destroy?; can_edit? && show?; end

  # Only admins (owner + admin) can change which folders are restricted
  # and who can see them. Members and viewers never manage permissions.
  def manage_permissions?
    admin?
  end

  class Scope < Scope
    def resolve
      return scope.none unless membership

      base = scope.where(workspace_id: membership.workspace_id)

      # Owners and admins see every folder in the workspace, no filtering.
      return base if membership.admin?

      # Non-admins see:
      #   - Folders with NO permission rows (i.e. public to workspace), OR
      #   - Folders where they have an explicit FolderPermission row.
      base.left_joins(:folder_permissions)
          .where(
            "folder_permissions.id IS NULL OR folder_permissions.user_id = ?",
            user.id
          )
          .distinct
    end
  end
end
