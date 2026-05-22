class InvitationPolicy < ApplicationPolicy
  # Only admins (owner or admin) can send invitations.
  def new?;    admin?; end
  def create?; admin?; end
end
