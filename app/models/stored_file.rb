class StoredFile < ApplicationRecord
  ALLOWED_CONTENT_TYPES = %w[
    application/pdf
    image/png image/jpeg image/gif image/webp
    text/plain text/csv
    application/msword
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/vnd.ms-excel
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
  ].freeze

  MAX_FILE_SIZE = 25.megabytes

  belongs_to :workspace
  belongs_to :user # uploader, kept for attribution
  belongs_to :folder

  has_one_attached :uploaded_file, dependent: :purge_later

  validates :file_name, presence: true
  validate :uploaded_file_attached
  validate :uploaded_file_content_type
  validate :uploaded_file_size

  scope :by_name, -> { order(file_name: :asc) }
  scope :search, ->(query) {
    sanitized = sanitize_sql_like(query.to_s)
    where("file_name ILIKE ?", "%#{sanitized}%")
  }

  private

  def uploaded_file_attached
    errors.add(:uploaded_file, "must be attached") unless uploaded_file.attached?
  end

  def uploaded_file_content_type
    return unless uploaded_file.attached?
    return if ALLOWED_CONTENT_TYPES.include?(uploaded_file.blob.content_type)
    errors.add(:uploaded_file, "must be a PDF, image, document, or spreadsheet")
  end

  def uploaded_file_size
    return unless uploaded_file.attached?
    return if uploaded_file.blob.byte_size <= MAX_FILE_SIZE
    errors.add(:uploaded_file, "must be #{MAX_FILE_SIZE / 1.megabyte}MB or less")
  end
end
