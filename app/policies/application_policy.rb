# Base class for all Pundit policies.
#
# pundit_user is set in ApplicationController to a PunditContext struct of
# (user, membership). Subclasses read `user` for identity, `membership` for
# the role-in-current-workspace check.
#
# Naming convention helpers (used widely below):
#
#   admin?     → owner or admin in this workspace
#   member?    → role == "member" exactly
#   viewer?    → role == "viewer" exactly
#   can_edit?  → anyone above viewer (member, admin, owner)
#
# Default deny: every action returns false until a subclass overrides it.
# That way, forgetting to write a policy method fails closed, not open.
class ApplicationPolicy
  attr_reader :context, :user, :membership, :record

  def initialize(context, record)
    @context    = context
    @user       = context&.user
    @membership = context&.membership
    @record     = record
  end

  def index?;   false; end
  def show?;    false; end
  def create?;  false; end
  def new?;     create?; end
  def update?;  false; end
  def edit?;    update?; end
  def destroy?; false; end

  protected

  def signed_in?
    user.present?
  end

  def admin?
    membership&.admin?
  end

  def owner?
    membership&.owner?
  end

  def can_edit?
    membership&.can_edit?
  end

  def viewer?
    membership&.viewer?
  end

  def any_member?
    membership.present?
  end

  class Scope
    attr_reader :context, :user, :membership, :scope

    def initialize(context, scope)
      @context    = context
      @user       = context&.user
      @membership = context&.membership
      @scope      = scope
    end

    def resolve
      raise NotImplementedError, "#{self.class} must implement #resolve"
    end
  end
end
