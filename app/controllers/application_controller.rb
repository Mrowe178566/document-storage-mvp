class ApplicationController < ActionController::Base
  include Pundit::Authorization

  protect_from_forgery with: :exception

  helper BreadcrumbsHelper
  include BreadcrumbsHelper

  helper_method :current_workspace, :current_membership

  # Pundit raises NotAuthorizedError when a policy returns false. Catch it and
  # send the user back somewhere safe with a clear message instead of crashing.
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Tell Pundit who's asking. We use a struct carrying the user AND their
  # membership in the current workspace so policies can read `user.membership`
  # without re-querying the DB on every authorize call.
  def pundit_user
    PunditContext.new(current_user, current_membership)
  end

  private

  PunditContext = Struct.new(:user, :membership)

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

  # Retained for back-compat with controllers/views that haven't been migrated
  # to Pundit yet. New code should authorize via policies instead.
  def require_workspace_admin
    return if current_membership&.admin?
    redirect_to authenticated_root_path, alert: "Only workspace admins can do that."
  end

  def require_workspace_owner
    return if current_membership&.owner?
    redirect_to authenticated_root_path, alert: "Only the workspace owner can do that."
  end

  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    Rails.logger.info "[pundit] #{current_user&.email} denied: #{policy_name}##{exception.query}"
    redirect_back_or_to(authenticated_root_path, allow_other_host: false,
                        alert: "You don't have permission to do that.")
  end
end
