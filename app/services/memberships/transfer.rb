module Memberships
  # Transfers workspace ownership in a single transaction:
  #   current owner  → admin
  #   target admin   → owner
  #
  # The target must already be an admin. We don't allow promoting a member
  # straight to owner — the previous step should be an explicit promotion.
  #
  # Wrapping in a transaction means the workspace is never observably
  # owner-less from outside the transaction, even though both rows must
  # change before constraints are satisfied.
  class Transfer
    Result = Struct.new(:success?, :new_owner, :error, keyword_init: true)

    def self.call(current_owner_membership:, new_owner_membership:)
      new(
        current_owner_membership: current_owner_membership,
        new_owner_membership: new_owner_membership
      ).call
    end

    def initialize(current_owner_membership:, new_owner_membership:)
      @current_owner_membership = current_owner_membership
      @new_owner_membership     = new_owner_membership
    end

    def call
      return failure("Only the current owner can transfer ownership.") unless @current_owner_membership&.owner?
      return failure("Ownership can only be transferred to an admin.") unless @new_owner_membership.role == "admin"

      Membership.transaction do
        @current_owner_membership.update!(role: "admin")
        @new_owner_membership.update!(role: "owner")
      end

      Result.new(success?: true, new_owner: @new_owner_membership.user, error: nil)
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages.to_sentence)
    end

    private

    def failure(message)
      Result.new(success?: false, new_owner: nil, error: message)
    end
  end
end
