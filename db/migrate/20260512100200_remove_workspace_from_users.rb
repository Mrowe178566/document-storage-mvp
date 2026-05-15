class RemoveWorkspaceFromUsers < ActiveRecord::Migration[8.0]
  def up
    remove_reference :users, :workspace, foreign_key: true
    remove_column :users, :role
  end

  def down
    add_column :users, :role, :string, null: false, default: "member"
    add_reference :users, :workspace, foreign_key: true

    # Best-effort restore: pick each user's "highest" membership and set it back.
    User.reset_column_information
    Membership.reset_column_information

    User.find_each do |user|
      membership = user.memberships
        .order(Arel.sql("CASE role WHEN 'owner' THEN 0 WHEN 'admin' THEN 1 ELSE 2 END"))
        .first
      next unless membership

      restored_role = membership.role == "owner" ? "admin" : membership.role
      user.update_columns(workspace_id: membership.workspace_id, role: restored_role)
    end
  end
end
