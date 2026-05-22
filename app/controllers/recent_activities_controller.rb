class RecentActivitiesController < ApplicationController
  before_action :authenticate_user!

  def index
    authorize current_workspace, :recent?
    @events = RecentActivityQuery.call(workspace: current_workspace, limit: 50)
    add_breadcrumb "Recent activity", recent_activities_path
  end
end
