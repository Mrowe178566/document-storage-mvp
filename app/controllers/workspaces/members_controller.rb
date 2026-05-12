class Workspaces::MembersController < ApplicationController
  before_action :authenticate_user!
  before_action :require_workspace_admin

  def destroy
    member = current_workspace.users.find(params[:id])

    if member == current_user
      redirect_to workspace_path, alert: "You can't remove yourself."
      return
    end

    member.destroy
    redirect_to workspace_path, notice: "#{member.email} removed from the workspace."
  end
end
