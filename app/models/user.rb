class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Virtual attribute used during signup to name the user's first workspace.
  attr_accessor :workspace_name

  has_many :memberships, dependent: :destroy
  has_many :workspaces, through: :memberships

  has_many :folders, dependent: :destroy
  has_many :stored_files, dependent: :destroy
  has_many :sent_invitations,
           class_name: "Invitation",
           foreign_key: :invited_by_id,
           dependent: :destroy

  def membership_for(workspace)
    return nil unless workspace
    memberships.find_by(workspace_id: workspace.id)
  end

  def role_in(workspace)
    membership_for(workspace)&.role
  end

  def owner_of?(workspace)
    role_in(workspace) == "owner"
  end

  def admin_of?(workspace)
    role = role_in(workspace)
    role == "owner" || role == "admin"
  end

  def member_of?(workspace)
    membership_for(workspace).present?
  end
end
