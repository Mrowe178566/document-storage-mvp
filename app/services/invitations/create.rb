module Invitations
  # Creates an Invitation for a workspace and dispatches the invite email.
  #
  # Rejects:
  #   - blank email
  #   - email already belongs to a workspace member
  #
  # Usage:
  #   result = Invitations::Create.call(workspace: ws, invited_by: current_user,
  #                                     email: "x@y.com", role: "viewer")
  class Create
    Result = Struct.new(:success?, :invitation, :error, keyword_init: true)

    def self.call(workspace:, invited_by:, email:, role: "member")
      new(workspace: workspace, invited_by: invited_by, email: email, role: role).call
    end

    def initialize(workspace:, invited_by:, email:, role:)
      @workspace  = workspace
      @invited_by = invited_by
      @email      = email.to_s.strip.downcase
      @role       = role.presence || "member"
    end

    def call
      return failure("Email can't be blank")                if @email.blank?
      return failure("#{@email} is already a member of this workspace") if already_member?

      invitation = @workspace.invitations.build(
        email: @email,
        invited_by: @invited_by,
        role: @role
      )

      if invitation.save
        InvitationMailer.invite(invitation).deliver_later
        Result.new(success?: true, invitation: invitation, error: nil)
      else
        failure(invitation.errors.full_messages.to_sentence)
      end
    end

    private

    def already_member?
      user = User.find_by(email: @email)
      return false unless user
      @workspace.users.exists?(id: user.id)
    end

    def failure(message)
      Result.new(success?: false, invitation: nil, error: message)
    end
  end
end
