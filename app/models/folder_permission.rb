# Explicit per-user access grant for a folder.
#
# Folders are workspace-public by default. When folder_permissions rows exist
# for a folder, the folder becomes "restricted": viewers and members can only
# see it if they're explicitly listed here. Admins and owners always see
# every folder regardless of restrictions (enforced in FolderPolicy::Scope).
class FolderPermission < ApplicationRecord
  belongs_to :folder
  belongs_to :user

  validates :user_id, uniqueness: { scope: :folder_id }
end
