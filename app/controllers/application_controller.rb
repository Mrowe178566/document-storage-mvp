class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  helper BreadcrumbsHelper
  include BreadcrumbsHelper

  helper_method :current_workspace

  private

  def current_workspace
    current_user&.workspace
  end

  def require_workspace_admin
    return if current_user&.admin?
    redirect_to authenticated_root_path, alert: "Only workspace admins can do that."
  end
end
