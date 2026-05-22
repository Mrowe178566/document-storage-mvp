class RecentActivitiesController < ApplicationController
  before_action :authenticate_user!

  def index
    authorize current_workspace, :recent?

    # Don't surface activity from folders the user can't see.
    visible_folder_ids = policy_scope(Folder).pluck(:id)
    @events = RecentActivityQuery.call(
      workspace: current_workspace,
      visible_folder_ids: visible_folder_ids,
      limit: 50
    )

    add_breadcrumb "Recent activity", recent_activities_path
  end
end
