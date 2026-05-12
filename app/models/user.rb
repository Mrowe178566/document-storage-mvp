class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :workspace

  has_many :folders, dependent: :destroy
  has_many :stored_files, dependent: :destroy
  has_many :sent_invitations,
           class_name: "Invitation",
           foreign_key: :invited_by_id,
           dependent: :destroy

  enum :role, { member: "member", admin: "admin" }, default: "member"

  before_validation :setup_default_workspace, on: :create, unless: -> { workspace }

  private

  def setup_default_workspace
    handle = email.to_s.split("@").first.presence || "user"
    self.workspace = Workspace.new(name: "#{handle.titleize}'s Workspace")
    self.role = "admin"
  end
end
