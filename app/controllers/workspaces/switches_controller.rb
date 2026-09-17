class Workspaces::SwitchesController < ApplicationController
  before_action :authenticate_user!

  def create
    # Route is `post :switch, on: :member`, so the workspace id arrives as :id.
    target = current_user.workspaces.find_by(id: params[:id])

    if target
      session[:current_workspace_id] = target.id
      redirect_to authenticated_root_path, notice: "Switched to #{target.name}."
    else
      redirect_back_or_to authenticated_root_path,
                          alert: "You don't belong to that workspace."
    end
  end
end
