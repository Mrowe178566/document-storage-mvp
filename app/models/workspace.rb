class Workspace < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :folders, dependent: :destroy
  has_many :stored_files, dependent: :destroy
  has_many :invitations, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, on: :create

  def admins
    users.where(role: "admin")
  end

  def members
    users.where(role: "member")
  end

  private

  def generate_slug
    return if slug.present?
    self.slug = SecureRandom.hex(6)
  end
end
