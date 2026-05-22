class Membership < ApplicationRecord
  # Roles, ordered from least → most privileged. The Membership#admin? helper
  # returns true for owner OR admin (i.e. "can manage workspace"); use #owner?
  # or #viewer? specifically when you need the exact role.
  ROLES = %w[viewer member admin owner].freeze

  belongs_to :user
  belongs_to :workspace

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :workspace_id }
  validate :only_one_owner_per_workspace, if: :owner?

  scope :owners,       -> { where(role: "owner") }
  scope :admins,       -> { where(role: [ "owner", "admin" ]) }
  scope :members_only, -> { where(role: "member") }
  scope :viewers,      -> { where(role: "viewer") }

  def owner?
    role == "owner"
  end

  # "admin?" means owner OR admin — i.e. allowed to manage workspace
  # settings, members, and invitations. Not the same as role == "admin".
  def admin?
    role == "owner" || role == "admin"
  end

  def member?
    role == "member"
  end

  def viewer?
    role == "viewer"
  end

  # Anyone above viewer can create/edit folders and files.
  def can_edit?
    role != "viewer"
  end

  private

  def only_one_owner_per_workspace
    existing = Membership.where(workspace_id: workspace_id, role: "owner").where.not(id: id)
    errors.add(:role, "workspace already has an owner") if existing.exists?
  end
end
