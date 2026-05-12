class RequireOwnerAssociations < ActiveRecord::Migration[8.0]
  # Folders and stored files were originally created with nullable owner
  # foreign keys. They should never be null in practice — every record is
  # built through `current_user.folders.build` or `folder.stored_files.build`
  # — so tighten the constraint at the database level.
  def change
    change_column_null :folders, :user_id, false
    change_column_null :stored_files, :user_id, false
    change_column_null :stored_files, :folder_id, false
  end
end
