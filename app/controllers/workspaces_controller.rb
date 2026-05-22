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

  def new
    @workspace = Workspace.new
    add_breadcrumb "New workspace"
  end

  def bootstrap
    result = Workspaces::Bootstrap.call(workspace: current_workspace, user: current_user)

    if result.success?
      message =
        if result.folders.any?
          "Added #{result.folders.size} starter #{'folder'.pluralize(result.folders.size)} to #{current_workspace.name}."
        else
          "Starter folders were already in place."
        end
      redirect_to folders_path, notice: message
    else
      redirect_to folders_path, alert: "Couldn't bootstrap workspace: #{result.error}"
    end
  end

  def create
    result = Workspaces::Create.call(user: current_user, name: workspace_params[:name])

    if result.success?
      session[:current_workspace_id] = result.workspace.id
      redirect_to authenticated_root_path,
                  notice: "Workspace #{result.workspace.name} created. You're now in it."
    else
      @workspace = Workspace.new(name: workspace_params[:name])
      flash.now[:alert] = result.error
      render :new, status: :unprocessable_entity
    end
  end

  private

  def workspace_params
    params.require(:workspace).permit(:name)
  end
end
