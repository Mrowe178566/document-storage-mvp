class InvitationsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_workspace_admin

  def new
    @invitation = current_workspace.invitations.new
    add_breadcrumb current_workspace.name, workspace_path
    add_breadcrumb "Invite member"
  end

  def create
    @invitation = current_workspace.invitations.build(invitation_params)
    @invitation.invited_by = current_user

    if existing_user?
      redirect_to new_workspace_invitation_path,
                  alert: "An account already exists for #{@invitation.email}."
      return
    end

    if @invitation.save
      InvitationMailer.invite(@invitation).deliver_later
      redirect_to workspace_path,
                  notice: "Invitation sent to #{@invitation.email}."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def invitation_params
    params.require(:invitation).permit(:email)
  end

  def existing_user?
    User.exists?(email: @invitation.email&.downcase)
  end
end
