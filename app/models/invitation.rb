class Invitation < ApplicationRecord
  EXPIRY_WINDOW = 7.days

  belongs_to :workspace
  belongs_to :invited_by, class_name: "User"

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  before_validation :generate_token_and_expiry, on: :create

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
      user.update!(workspace: workspace, role: "member")
      update!(accepted_at: Time.current)
    end
  end

  private

  def generate_token_and_expiry
    self.token ||= SecureRandom.urlsafe_base64(32)
    self.expires_at ||= EXPIRY_WINDOW.from_now
  end
end
