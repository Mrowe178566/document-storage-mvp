# Manages who can see a restricted folder.
#
# Routes:
#   GET   /folders/:folder_id/permissions/edit  → edit
#   PATCH /folders/:folder_id/permissions       → update
#
# The update action takes a visibility radio plus an array of user_ids.
# Submitting visibility=public destroys all permission rows. Submitting
# visibility=restricted diffs the user_ids against current rows and creates
# or destroys to match the form state.
class FolderPermissionsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_folder

  def edit
    authorize @folder, :manage_permissions?
    @workspace_users = current_workspace.users.order(:email).to_a
    @granted_user_ids = @folder.folder_permissions.pluck(:user_id).to_set
    add_breadcrumb "Folders", folders_path
    add_breadcrumb @folder.name, folder_path(@folder)
    add_breadcrumb "Manage access"
  end

  def update
    authorize @folder, :manage_permissions?

    if params[:visibility] == "public"
      @folder.folder_permissions.destroy_all
      redirect_to folder_path(@folder), notice: "#{@folder.name} is now visible to the whole workspace."
    else
      apply_restricted_changes
      redirect_to folder_path(@folder),
                  notice: "Access to #{@folder.name} updated. #{@folder.folder_permissions.count} #{'person'.pluralize(@folder.folder_permissions.count)} can see it."
    end
  end

  private

  def load_folder
    @folder = current_workspace.folders.find(params[:folder_id])
  end

  # Diffs the submitted user_ids against existing rows and creates/destroys
  # so the database matches the form. Done in a single transaction so the
  # folder is never in a half-updated state.
  def apply_restricted_changes
    submitted_ids = (params[:user_ids] || []).map(&:to_i).to_set
    current_ids   = @folder.folder_permissions.pluck(:user_id).to_set

    to_add    = submitted_ids - current_ids
    to_remove = current_ids - submitted_ids

    FolderPermission.transaction do
      to_add.each { |uid| @folder.folder_permissions.create!(user_id: uid) }
      @folder.folder_permissions.where(user_id: to_remove.to_a).destroy_all if to_remove.any?
    end
  end
end
