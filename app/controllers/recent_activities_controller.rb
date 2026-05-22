class RecentActivitiesController < ApplicationController
  before_action :authenticate_user!

  def index
    @events = RecentActivityQuery.call(workspace: current_workspace, limit: 50)
    add_breadcrumb "Recent activity", recent_activities_path
  end
end
