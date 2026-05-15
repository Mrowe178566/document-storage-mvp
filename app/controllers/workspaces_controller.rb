class WorkspacesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_workspace_admin, only: [ :update ]

  def show
    @workspace = current_workspace
    @memberships = @workspace.memberships.includes(:user).to_a.sort_by do |m|
      [ Membership::ROLES.reverse.index(m.role), m.user.email ]
    end
    @pending_invitations = @workspace.invitations.pending.order(created_at: :desc)
    add_breadcrumb @workspace.name
  end

  def update
    if current_workspace.update(workspace_params)
      redirect_to workspace_path, notice: "Workspace updated."
    else
      redirect_to workspace_path, alert: current_workspace.errors.full_messages.to_sentence
    end
  end

  private

  def workspace_params
    params.require(:workspace).permit(:name)
  end
end
