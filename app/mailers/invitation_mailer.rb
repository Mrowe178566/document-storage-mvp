class InvitationMailer < ApplicationMailer
  def invite(invitation)
    @invitation = invitation
    @workspace = invitation.workspace
    @inviter = invitation.invited_by
    @accept_url = invitation_acceptance_url(token: invitation.token)

    mail(
      to: invitation.email,
      subject: "#{@inviter.email} invited you to #{@workspace.name} on File Vault"
    )
  end
end
