module Memberships
  # An admin removing someone else from the workspace.
  # The workspace owner cannot be removed.
  class Remove
    Result = Struct.new(:success?, :removed_user, :error, keyword_init: true)

    def self.call(membership:)
      new(membership: membership).call
    end

    def initialize(membership:)
      @membership = membership
    end

    def call
      return failure("The workspace owner can't be removed.") if @membership.owner?

      removed = @membership.user
      @membership.destroy
      Result.new(success?: true, removed_user: removed, error: nil)
    end

    private

    def failure(message)
      Result.new(success?: false, removed_user: nil, error: message)
    end
  end
end
