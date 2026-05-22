module Memberships
  # A user removing themselves from a workspace.
  #
  # Guards:
  #   - Owners must transfer ownership first.
  #   - A user can't leave their only workspace (would orphan them).
  #
  # On success returns Result with next_workspace, so the caller can switch
  # the session to a workspace the user still belongs to.
  class Leave
    Result = Struct.new(:success?, :next_workspace, :error, keyword_init: true)

    def self.call(membership:, user:)
      new(membership: membership, user: user).call
    end

    def initialize(membership:, user:)
      @membership = membership
      @user       = user
    end

    def call
      return failure("Transfer ownership before leaving the workspace.") if @membership.owner?
      return failure("You can't leave your only workspace. Join another first.") if only_workspace?

      next_ws = nil
      Membership.transaction do
        next_ws = next_workspace_for(@user, leaving_workspace_id: @membership.workspace_id)
        @membership.destroy!
      end

      Result.new(success?: true, next_workspace: next_ws, error: nil)
    end

    private

    def only_workspace?
      @user.workspaces.count <= 1
    end

    def next_workspace_for(user, leaving_workspace_id:)
      user.workspaces.where.not(id: leaving_workspace_id).order(:created_at).first
    end

    def failure(message)
      Result.new(success?: false, next_workspace: nil, error: message)
    end
  end
end
