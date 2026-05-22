module Memberships
  # Demotes an admin back to member. The workspace owner cannot be demoted —
  # ownership must be transferred first.
  class Demote
    Result = Struct.new(:success?, :membership, :error, keyword_init: true)

    def self.call(membership:)
      new(membership: membership).call
    end

    def initialize(membership:)
      @membership = membership
    end

    def call
      return failure("The workspace owner can't be demoted. Transfer ownership first.") if @membership.owner?
      return failure("Only admins can be demoted.") unless @membership.role == "admin"

      if @membership.update(role: "member")
        Result.new(success?: true, membership: @membership, error: nil)
      else
        failure(@membership.errors.full_messages.to_sentence)
      end
    end

    private

    def failure(message)
      Result.new(success?: false, membership: @membership, error: message)
    end
  end
end
