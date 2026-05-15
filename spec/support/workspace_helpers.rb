module WorkspaceHelpers
  # Create a user as the owner of a brand-new workspace.
  # Returns [user, workspace].
  def create_owner_with_workspace(email: nil, workspace_name: "Test Workspace")
    email ||= "owner-#{SecureRandom.hex(4)}@example.com"
    user = User.create!(email: email, password: "password")
    workspace = Workspace.create!(name: workspace_name)
    Membership.create!(user: user, workspace: workspace, role: "owner")
    [ user, workspace ]
  end

  # Add a user to an existing workspace at the given role.
  # Returns the user.
  def create_member(workspace, email: nil, role: "member")
    email ||= "user-#{SecureRandom.hex(4)}@example.com"
    user = User.create!(email: email, password: "password")
    Membership.create!(user: user, workspace: workspace, role: role)
    user
  end
end
