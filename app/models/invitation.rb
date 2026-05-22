class Invitation < ApplicationRecord
  EXPIRY_WINDOW = 7.days

  # Only "viewer", "member", and "admin" can be invited.
  # Owner is not an invitable role — ownership is granted at signup and
  # transferred via the Memberships::Transfer service.
  INVITABLE_ROLES = %w[viewer member admin].freeze

  belongs_to :workspace
  belongs_to :invited_by, class_name: "User"

  validates :email,      presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token,      presence: true, uniqueness: true
  validates :expires_at, presence: true
  validates :role,       presence: true, inclusion: { in: INVITABLE_ROLES }

  before_validation :generate_token_and_expiry, on: :create
  before_validation :default_role, on: :create

  scope :pending, -> { where(accepted_at: nil).where("expires_at > ?", Time.current) }

  def accepted?
    accepted_at.present?
  end

  def expired?
    expires_at < Time.current
  end

  def usable?
    !accepted? && !expired?
  end

  def accept!(user)
    transaction do
      # Use the role stored on the invitation. Falls back to "member" for
      # any legacy invitation rows where role might be unexpectedly nil.
      Membership.find_or_create_by!(user: user, workspace: workspace) do |m|
        m.role = role.presence || "member"
      end
      update!(accepted_at: Time.current)
    end
  end

  private

  def generate_token_and_expiry
    self.token       ||= SecureRandom.urlsafe_base64(32)
    self.expires_at  ||= EXPIRY_WINDOW.from_now
  end

  def default_role
    self.role ||= "member"
  end
end
