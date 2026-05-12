class InvitationAcceptancesController < ApplicationController
  before_action :set_invitation
  before_action :reject_unusable_invitation

  def show
    @user = User.new(email: @invitation.email)
  end

  def update
    @user = User.new(user_params)
    @user.email = @invitation.email
    @user.workspace = @invitation.workspace
    @user.role = "member"

    if @user.save
      @invitation.update!(accepted_at: Time.current)
      sign_in(@user)
      redirect_to authenticated_root_path,
                  notice: "Welcome to #{@invitation.workspace.name}."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_invitation
    @invitation = Invitation.find_by(token: params[:token])
    redirect_to new_user_session_path, alert: "Invitation not found." if @invitation.nil?
  end

  def reject_unusable_invitation
    return if @invitation.nil?
    return if @invitation.usable?

    message =
      if @invitation.accepted?
        "That invitation has already been accepted. Sign in to continue."
      else
        "That invitation has expired."
      end

    redirect_to new_user_session_path, alert: message
  end

  def user_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
