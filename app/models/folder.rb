# == Schema Information
#
# Table name: folders
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint
#
# Indexes
#
#  index_folders_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Folder < ApplicationRecord
  belongs_to :user
  has_many :stored_files, dependent: :destroy
  
  validates :name, presence: true
end
