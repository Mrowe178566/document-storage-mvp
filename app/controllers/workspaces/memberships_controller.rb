class Workspaces::MembershipsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_membership

  # PATCH /workspace/memberships/:id
  # Body: role=admin (promote), role=member (demote), role=owner (transfer)
  def update
    authorize @membership

    result =
      case params[:role]
      when "admin"  then Memberships::Promote.call(membership: @membership)
      when "member" then Memberships::Demote.call(membership: @membership)
      when "owner"  then transfer_result
      else
        return redirect_to(workspace_path, alert: "Unknown role action.")
      end

    if result.success?
      redirect_to workspace_path, notice: success_message_for(params[:role], result)
    else
      redirect_to workspace_path, alert: result.error
    end
  end

  # DELETE /workspace/memberships/:id
  # Either a member self-leaving or an admin removing someone else.
  def destroy
    authorize @membership

    if @membership.user == current_user
      handle_self_leave
    else
      handle_admin_remove
    end
  end

  private

  def load_membership
    @membership = current_workspace.memberships.find(params[:id])
  end

  def transfer_result
    Memberships::Transfer.call(
      current_owner_membership: current_membership,
      new_owner_membership: @membership
    )
  end

  def success_message_for(action, result)
    case action
    when "admin"  then "#{@membership.user.email} is now an admin."
    when "member" then "#{@membership.user.email} is now a member."
    when "owner"  then "Ownership transferred to #{result.new_owner.email}."
    end
  end

  def handle_self_leave
    result = Memberships::Leave.call(membership: @membership, user: current_user)

    if result.success?
      session[:current_workspace_id] = result.next_workspace&.id
      redirect_to authenticated_root_path,
                  notice: "You left #{@membership.workspace.name}."
    else
      redirect_to workspace_path, alert: result.error
    end
  end

  def handle_admin_remove
    result = Memberships::Remove.call(membership: @membership)

    if result.success?
      redirect_to workspace_path,
                  notice: "#{result.removed_user.email} was removed from the workspace."
    else
      redirect_to workspace_path, alert: result.error
    end
  end
end
