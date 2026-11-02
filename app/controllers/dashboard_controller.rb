class DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    authorize current_workspace, :show?, policy_class: WorkspacePolicy

    # policy_scope honors per-folder permissions — non-admins only see folders
    # they're allowed to. Admins see everything via FolderPolicy::Scope.
    visible_folders = policy_scope(Folder)

    @dashboard = {
      folder_count: visible_folders.count,
      file_count: current_workspace.stored_files.count,
      member_count: current_workspace.memberships.count,
      role: current_membership&.role,
      suggested_folders: SuggestedFoldersQuery.call(
        workspace: current_workspace,
        visible_folders: visible_folders,
        limit: 4
      ),
      recent_activity: RecentActivityQuery.call(
        workspace: current_workspace,
        visible_folder_ids: visible_folders.pluck(:id),
        limit: 10
      )
    }
  end
end
