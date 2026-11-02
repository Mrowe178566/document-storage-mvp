class StoredFilePolicy < ApplicationPolicy
  # Viewers can see and download files; that's the whole point of the viewer
  # role. Every per-file action also requires access to the file's folder, so
  # restricted folders protect their files, not just the folder page.
  def show?;     folder_accessible?; end
  def download?; folder_accessible?; end

  # Only non-viewers can upload or delete.
  def create?;      can_edit? && folder_accessible?; end
  def destroy?;     can_edit? && folder_accessible?; end
  def bulk_delete?; can_edit?; end

  # Files the user may act on: those in folders FolderPolicy::Scope lets them
  # see, which already handles restricted folders and admin access.
  class Scope < Scope
    def resolve
      return scope.none unless membership
      scope.where(folder_id: FolderPolicy::Scope.new(context, Folder).resolve.select(:id))
    end
  end

  private

  # Checks the workspace too, so a file from another workspace is never
  # allowed even if a controller forgets to scope its lookup.
  def folder_accessible?
    return false unless any_member? && record.workspace_id == membership.workspace_id
    record.folder.accessible_by?(user, membership: membership)
  end
end
