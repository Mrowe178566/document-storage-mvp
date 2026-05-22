class AddRoleToInvitations < ActiveRecord::Migration[8.0]
  def change
    add_column :invitations, :role, :string, default: "member", null: false

    # Backfill: existing invitations all default to "member" since that's
    # what they would have become on accept under the old code.
    reversible do |dir|
      dir.up do
        execute "UPDATE invitations SET role = 'member' WHERE role IS NULL"
      end
    end
  end
end
