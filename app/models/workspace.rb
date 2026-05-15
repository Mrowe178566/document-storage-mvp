class Workspace < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :folders, dependent: :destroy
  has_many :stored_files, dependent: :destroy
  has_many :invitations, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, on: :create

  def owner
    memberships.find_by(role: "owner")&.user
  end

  def admins
    User.joins(:memberships).where(memberships: { workspace_id: id, role: [ "owner", "admin" ] })
  end

  def members
    User.joins(:memberships).where(memberships: { workspace_id: id, role: "member" })
  end

  private

  def generate_slug
    return if slug.present?
    self.slug = SecureRandom.hex(6)
  end
end
