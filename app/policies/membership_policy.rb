class MembershipPolicy < ApplicationPolicy
  # Admins can promote members, demote admins, and change roles in general.
  # Viewers and members can't manage roles at all.
  def update?
    admin? && !record.owner?
  end

  # Transferring ownership is only the current owner's call, and only TO an
  # existing admin (the receiving membership must currently be admin).
  def transfer?
    owner? && record.admin? && !record.owner?
  end

  # Admins can remove anyone except the workspace owner.
  # A user can always remove (leave) themselves, regardless of role.
  def destroy?
    return false unless any_member?
    return false if record.owner?
    record.user_id == user.id || admin?
  end

  # Self-leave is a special case of destroy? handled by the service.
  def leave?
    record.user_id == user.id && !record.owner?
  end
end
