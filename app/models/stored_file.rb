# == Schema Information
#
# Table name: stored_files
#
#  id         :bigint           not null, primary key
#  file_name  :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  folder_id  :bigint
#  user_id    :bigint
#
# Indexes
#
#  index_stored_files_on_folder_id  (folder_id)
#  index_stored_files_on_user_id    (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (folder_id => folders.id)
#  fk_rails_...  (user_id => users.id)
#
class StoredFile < ApplicationRecord
  belongs_to :user
  belongs_to :folder

  validates :file_name, presence: true

  # How were certain that files were deleted from a cloud storage provider when the file is deleted from the database? Currently there is no job visible in the codebase that indicates that there is a background job that is responsible for deleting files from the cloud storage provider when the file is deleted from the database. If you aren't running a separate worker process, the job might just sit in the database table (solid_queue_jobs) and the file will never actually disappear from your storage. 
  has_one_attached :uploaded_file, dependent: :purge_later
end
