class Folder < ApplicationRecord
  belongs_to :workspace
  belongs_to :user # creator, kept for attribution

  has_many :stored_files, dependent: :destroy

  validates :name, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
