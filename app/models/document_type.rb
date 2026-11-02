# A kind of document a workspace keeps, like "Insurance certificate" or
# "Tax form". Each workspace has its own list and its own settings.
#
# Behavior comes from the settings (expires, valid_for_months,
# remind_days_before, requires_approval), never from the name. Code should
# never check whether a type is called "Certificate".
class DocumentType < ApplicationRecord
  MAX_VALID_MONTHS = 120
  MAX_REMIND_DAYS = 365

  belongs_to :workspace
  has_many :stored_files, dependent: :nullify

  normalizes :name, with: ->(name) { name.squish }

  validates :name, presence: true, length: { maximum: 60 },
                   uniqueness: { scope: :workspace_id, case_sensitive: false,
                                 message: "is already used by another document type" }

  with_options if: :expires? do
    validates :valid_for_months, presence: true,
              numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: MAX_VALID_MONTHS }
    validates :remind_days_before, presence: true,
              numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: MAX_REMIND_DAYS }
  end

  before_validation :clear_expiry_settings, unless: :expires?

  scope :by_name, -> { order(Arel.sql("lower(name)")) }

  # The date a document of this type runs out, counted from the date it was
  # issued. Used to fill in a file's expires_on when it is uploaded. The file
  # keeps that date, so editing the type later doesn't move it.
  def expires_on_for(issued_on)
    return unless expires?
    issued_on.to_date.advance(months: valid_for_months)
  end

  # The date to start warning people about that document.
  def remind_on_for(issued_on)
    expires_on_for(issued_on)&.advance(days: -remind_days_before)
  end

  private

  def clear_expiry_settings
    self.valid_for_months = nil
    self.remind_days_before = nil
  end
end
