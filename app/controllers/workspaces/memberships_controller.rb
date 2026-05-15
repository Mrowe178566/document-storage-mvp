class Workspaces::MembershipsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_membership

  # PATCH /workspace/memberships/:id
  # Body: role=admin (promote), role=member (demote), role=owner (transfer)
  def update
    case params[:role]
    when "admin"  then promote_to_admin
    when "member" then demote_to_member
    when "owner"  then transfer_ownership
    else
      redirect_to workspace_path, alert: "Unknown role action."
    end
  end

  # DELETE /workspace/memberships/:id
  # Either a member self-leaving or an admin removing someone else.
  def destroy
    if @membership.user == current_user
      self_leave
    else
      admin_remove
    end
  end

  private

  def load_membership
    @membership = current_workspace.memberships.find(params[:id])
  end

  def promote_to_admin
    return deny_admin_action unless current_membership&.admin?
    return redirect_to(workspace_path, alert: "That member can't be promoted.") unless @membership.member?

    @membership.update!(role: "admin")
    redirect_to workspace_path, notice: "#{@membership.user.email} is now an admin."
  end

  def demote_to_member
    return deny_admin_action unless current_membership&.admin?
    return redirect_to(workspace_path, alert: "The workspace owner can't be demoted.") if @membership.owner?
    return redirect_to(workspace_path, alert: "Nothing to demote.") unless @membership.role == "admin"

    @membership.update!(role: "member")
    redirect_to workspace_path, notice: "#{@membership.user.email} is now a member."
  end

  def transfer_ownership
    return redirect_to(workspace_path, alert: "Only the owner can transfer ownership.") unless current_membership&.owner?
    return redirect_to(workspace_path, alert: "You can only transfer ownership to another admin.") unless @membership.admin? && !@membership.owner?

    Membership.transaction do
      current_membership.update!(role: "admin")
      @membership.update!(role: "owner")
    end
    redirect_to workspace_path, notice: "Ownership transferred to #{@membership.user.email}."
  end

  def self_leave
    if @membership.owner?
      return redirect_to(workspace_path, alert: "Transfer ownership before leaving the workspace.")
    end

    if current_user.workspaces.count <= 1
      return redirect_to(workspace_path,
                         alert: "You can't leave your only workspace. Join another first.")
    end

    @membership.destroy
    switch_to_another_workspace
    redirect_to authenticated_root_path,
                notice: "You left #{@membership.workspace.name}."
  end

  def admin_remove
    return deny_admin_action unless current_membership&.admin?
    return redirect_to(workspace_path, alert: "The workspace owner can't be removed.") if @membership.owner?

    @membership.destroy
    redirect_to workspace_path, notice: "#{@membership.user.email} was removed from the workspace."
  end

  def deny_admin_action
    redirect_to workspace_path, alert: "Only workspace admins can do that."
  end

  def switch_to_another_workspace
    next_workspace = current_user.workspaces.where.not(id: current_workspace.id).order(:created_at).first
    session[:current_workspace_id] = next_workspace&.id
  end
end
