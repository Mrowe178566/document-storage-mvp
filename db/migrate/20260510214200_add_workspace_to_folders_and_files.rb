class AddWorkspaceToFoldersAndFiles < ActiveRecord::Migration[8.0]
  class MigrationFolder < ActiveRecord::Base
    self.table_name = "folders"
  end

  class MigrationStoredFile < ActiveRecord::Base
    self.table_name = "stored_files"
  end

  class MigrationUser < ActiveRecord::Base
    self.table_name = "users"
  end

  def up
    add_reference :folders, :workspace, foreign_key: true
    add_reference :stored_files, :workspace, foreign_key: true

    # Backfill workspace_id from the owning user's workspace.
    MigrationFolder.where(workspace_id: nil).find_each do |folder|
      user = MigrationUser.find(folder.user_id)
      folder.update_columns(workspace_id: user.workspace_id)
    end

    MigrationStoredFile.where(workspace_id: nil).find_each do |file|
      user = MigrationUser.find(file.user_id)
      file.update_columns(workspace_id: user.workspace_id)
    end

    change_column_null :folders, :workspace_id, false
    change_column_null :stored_files, :workspace_id, false
  end

  def down
    remove_reference :stored_files, :workspace, foreign_key: true
    remove_reference :folders, :workspace, foreign_key: true
  end
end
