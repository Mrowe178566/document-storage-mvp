class FoldersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_folder, only: [ :show, :edit, :update, :destroy ]

  def index
    authorize current_workspace, :show?, policy_class: WorkspacePolicy

    # policy_scope honors per-folder permissions — non-admins only see folders
    # they're allowed to. Admins see everything via FolderPolicy::Scope.
    visible_folders = policy_scope(Folder)
    @folders = visible_folders.recent

    @dashboard = {
      folder_count: visible_folders.count,
      file_count: current_workspace.stored_files.count,
      member_count: current_workspace.memberships.count,
      role: current_membership&.role,
      suggested_folders: SuggestedFoldersQuery.call(
        workspace: current_workspace,
        visible_folders: visible_folders,
        limit: 4
      ),
      recent_activity: RecentActivityQuery.call(
        workspace: current_workspace,
        visible_folder_ids: visible_folders.pluck(:id),
        limit: 10
      )
    }

    add_breadcrumb "Folders", folders_path
  end

  def show
    authorize @folder
    @files = @folder.stored_files
    @files = @files.search(params[:query]) if params[:query].present?
    @stored_file = StoredFile.new
    add_breadcrumb "Folders", folders_path
    add_breadcrumb @folder.name
  end

  def new
    @folder = current_workspace.folders.new
    authorize @folder
    add_breadcrumb "Folders", folders_path
    add_breadcrumb "New"
  end

  def create
    @folder = current_workspace.folders.build(folder_params)
    @folder.user = current_user
    authorize @folder

    if @folder.save
      redirect_to folders_path, notice: "Folder created successfully."
    else
      render :new
    end
  end

  def edit
    authorize @folder
    add_breadcrumb "Folders", folders_path
    add_breadcrumb "Edit #{@folder.name}"
  end

  def update
    authorize @folder
    if @folder.update(folder_params)
      redirect_to folders_path, notice: "Folder updated successfully."
    else
      render :edit
    end
  end

  def destroy
    authorize @folder
    @folder.destroy
    redirect_to folders_path, notice: "Folder deleted successfully."
  end

  private

  def set_folder
    @folder = current_workspace.folders.find(params[:id])
  end

  def folder_params
    params.require(:folder).permit(:name)
  end
end
