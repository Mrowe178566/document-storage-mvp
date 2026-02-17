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
end
