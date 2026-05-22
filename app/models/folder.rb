class Folder < ApplicationRecord
  belongs_to :workspace
  belongs_to :user # creator, kept for attribution

  has_many :stored_files,       dependent: :destroy
  has_many :folder_permissions, dependent: :destroy
  has_many :authorized_users,   through: :folder_permissions, source: :user

  validates :name, presence: true

  scope :recent, -> { order(created_at: :desc) }

  # A folder is "restricted" iff it has any folder_permissions rows.
  # No rows = public to the whole workspace (default behavior).
  def restricted?
    folder_permissions.exists?
  end

  # The single source of truth for "can this person see this folder?".
  # Used by FolderPolicy#show? and by queries that need to filter feeds
  # (RecentActivityQuery, SuggestedFoldersQuery).
  def accessible_by?(user, membership:)
    return false unless membership
    return true if membership.admin?                # owner + admin: see all
    return true unless restricted?                  # unrestricted: anyone in workspace
    folder_permissions.exists?(user_id: user.id)   # restricted: must be granted
  end
end
