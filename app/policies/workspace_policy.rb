class WorkspacePolicy < ApplicationPolicy
  # Any member (including viewer) can view the workspace settings page,
  # the team page, recent activity, and the dashboard.
  def show?;     any_member?; end
  def team?;     any_member?; end
  def recent?;   any_member?; end
  def dashboard?; any_member?; end

  # Only admins (owner or admin) can rename the workspace, run the bootstrap
  # service, or change other settings.
  def update?;    admin?; end
  def bootstrap?; admin?; end
  def manage?;    admin?; end

  # Anyone signed in can create a new workspace — they become its Owner.
  def create?; signed_in?; end
  def new?;    create?; end
end
