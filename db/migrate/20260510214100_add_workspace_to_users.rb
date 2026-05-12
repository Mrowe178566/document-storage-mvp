class AddWorkspaceToUsers < ActiveRecord::Migration[8.0]
  # Local model classes used only inside this migration so it doesn't depend on
  # the application models, which may change over time.
  class MigrationUser < ActiveRecord::Base
    self.table_name = "users"
  end

  class MigrationWorkspace < ActiveRecord::Base
    self.table_name = "workspaces"
  end

  def up
    add_column :users, :role, :string, null: false, default: "member"
    add_reference :users, :workspace, foreign_key: true

    # Backfill: every existing user becomes the admin of their own new workspace.
    MigrationUser.where(workspace_id: nil).find_each do |user|
      handle = user.email.to_s.split("@").first.presence || "user"
      workspace = MigrationWorkspace.create!(
        name: "#{handle.titleize}'s Workspace",
        slug: SecureRandom.hex(6)
      )
      user.update_columns(workspace_id: workspace.id, role: "admin")
    end

    change_column_null :users, :workspace_id, false
  end

  def down
    remove_reference :users, :workspace, foreign_key: true
    remove_column :users, :role
  end
end
