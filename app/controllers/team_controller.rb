class TeamController < ApplicationController
  before_action :authenticate_user!

  def index
    @memberships = current_workspace.memberships.includes(:user).to_a.sort_by do |m|
      [ Membership::ROLES.reverse.index(m.role), m.user.email ]
    end
    @pending_invitations = current_workspace.invitations.pending.order(created_at: :desc)
    add_breadcrumb "Team", team_path
  end
end
