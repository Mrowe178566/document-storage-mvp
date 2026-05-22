module Memberships
  # Promotes a membership from member → admin (or viewer → admin, since the
  # role transition is a single column update). The owner role is not reachable
  # via this service — use Memberships::Transfer for that.
  class Promote
    Result = Struct.new(:success?, :membership, :error, keyword_init: true)

    def self.call(membership:)
      new(membership: membership).call
    end

    def initialize(membership:)
      @membership = membership
    end

    def call
      return failure("The workspace owner is already at the top role.") if @membership.owner?
      return failure("That member is already an admin.")                 if @membership.role == "admin"

      if @membership.update(role: "admin")
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
