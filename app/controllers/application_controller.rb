class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  helper BreadcrumbsHelper
  include BreadcrumbsHelper

  helper_method :current_workspace, :current_membership

  private

  def current_workspace
    return @current_workspace if defined?(@current_workspace)
    @current_workspace = load_current_workspace
  end

  def current_membership
    return nil unless current_user && current_workspace
    @current_membership ||= current_user.membership_for(current_workspace)
  end

  def load_current_workspace
    return nil unless current_user

    selected_id = session[:current_workspace_id]
    workspace = current_user.workspaces.find_by(id: selected_id) if selected_id
    workspace ||= current_user.workspaces.order(:created_at).first

    if workspace && session[:current_workspace_id] != workspace.id
      session[:current_workspace_id] = workspace.id
    end

    workspace
  end

  def require_workspace_admin
    return if current_membership&.admin?
    redirect_to authenticated_root_path, alert: "Only workspace admins can do that."
  end

  def require_workspace_owner
    return if current_membership&.owner?
    redirect_to authenticated_root_path, alert: "Only the workspace owner can do that."
  end
end
