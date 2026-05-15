class Membership < ApplicationRecord
  ROLES = %w[member admin owner].freeze

  belongs_to :user
  belongs_to :workspace

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :workspace_id }
  validate :only_one_owner_per_workspace, if: :owner?

  scope :owners, -> { where(role: "owner") }
  scope :admins, -> { where(role: [ "owner", "admin" ]) }
  scope :members_only, -> { where(role: "member") }

  def owner?
    role == "owner"
  end

  def admin?
    role == "owner" || role == "admin"
  end

  def member?
    role == "member"
  end

  private

  def only_one_owner_per_workspace
    existing = Membership.where(workspace_id: workspace_id, role: "owner").where.not(id: id)
    errors.add(:role, "workspace already has an owner") if existing.exists?
  end
end
