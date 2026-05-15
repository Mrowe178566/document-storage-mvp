class InvitationAcceptancesController < ApplicationController
  before_action :set_invitation
  before_action :reject_unusable_invitation

  def show
    if existing_user
      handle_existing_user_show
    else
      @user = User.new(email: @invitation.email)
      render :show
    end
  end

  def update
    if existing_user
      handle_existing_user_update
    else
      handle_new_user_update
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

  def existing_user
    @existing_user ||= User.find_by(email: @invitation.email&.downcase)
  end

  # SHOW handlers

  def handle_existing_user_show
    if user_signed_in? && current_user == existing_user
      render :show_existing
    elsif user_signed_in?
      redirect_to authenticated_root_path,
                  alert: "This invitation is for #{@invitation.email}. Sign out and sign in as that user to accept."
    else
      store_location_for(:user, request.url)
      flash[:notice] = "Sign in to accept your invitation to #{@invitation.workspace.name}."
      redirect_to new_user_session_path
    end
  end

  # UPDATE handlers

  def handle_new_user_update
    @user = User.new(user_params)
    @user.email = @invitation.email

    saved = User.transaction do
      if @user.save
        @invitation.accept!(@user)
        session[:current_workspace_id] = @invitation.workspace.id
        true
      else
        false
      end
    end

    if saved
      sign_in(@user)
      redirect_to authenticated_root_path,
                  notice: "Welcome to #{@invitation.workspace.name}."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def handle_existing_user_update
    unless user_signed_in?
      store_location_for(:user, request.url)
      redirect_to new_user_session_path,
                  alert: "Sign in to accept your invitation."
      return
    end

    unless current_user == existing_user
      redirect_to authenticated_root_path,
                  alert: "This invitation is for #{@invitation.email}. Sign out and sign in as that user to accept."
      return
    end

    @invitation.accept!(current_user)
    session[:current_workspace_id] = @invitation.workspace.id
    redirect_to authenticated_root_path,
                notice: "You joined #{@invitation.workspace.name}."
  end

  def user_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
