class InvitationsController < ApplicationController
  before_action :authenticate_user!

  def new
    @invitation = current_workspace.invitations.new
    authorize @invitation
    add_breadcrumb current_workspace.name, workspace_path
    add_breadcrumb "Invite member"
  end

  def create
    @invitation = current_workspace.invitations.build(invitation_params)
    @invitation.invited_by = current_user
    authorize @invitation

    result = Invitations::Create.call(
      workspace: current_workspace,
      invited_by: current_user,
      email: invitation_params[:email],
      role: invitation_params[:role]
    )

    if result.success?
      redirect_to workspace_path, notice: "Invitation sent to #{result.invitation.email}."
    else
      redirect_to new_workspace_invitation_path, alert: result.error
    end
  end

  private

  def invitation_params
    params.require(:invitation).permit(:email, :role)
  end
end
