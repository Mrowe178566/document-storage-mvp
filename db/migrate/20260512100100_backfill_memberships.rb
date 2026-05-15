class BackfillMemberships < ActiveRecord::Migration[8.0]
  class MigrationUser < ActiveRecord::Base
    self.table_name = "users"
  end

  class MigrationWorkspace < ActiveRecord::Base
    self.table_name = "workspaces"
  end

  class MigrationMembership < ActiveRecord::Base
    self.table_name = "memberships"
  end

  def up
    # For each workspace: pick the earliest-created admin and make them owner.
    # Other admins become "admin"; members stay "member".
    MigrationWorkspace.find_each do |workspace|
      members_in_workspace = MigrationUser
        .where(workspace_id: workspace.id)
        .order(created_at: :asc, id: :asc)

      first_admin_seen = false
      members_in_workspace.find_each do |user|
        role =
          case user.role
          when "admin"
            if first_admin_seen
              "admin"
            else
              first_admin_seen = true
              "owner"
            end
          else
            "member"
          end

        MigrationMembership.create!(
          user_id: user.id,
          workspace_id: workspace.id,
          role: role,
          created_at: Time.current,
          updated_at: Time.current
        )
      end
    end
  end

  def down
    MigrationMembership.delete_all
  end
end
