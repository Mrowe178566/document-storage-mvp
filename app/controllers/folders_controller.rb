class FoldersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_folder, only: [:show, :edit, :update, :destroy]

  def index
    @folders = current_user.folders.recent
    add_breadcrumb "Folders", folders_path
  end

  def show
    @files = @folder.stored_files
    @files = @files.search(params[:query]) if params[:query].present?
    @stored_file = StoredFile.new
    add_breadcrumb "Folders", folders_path
    add_breadcrumb @folder.name
  end

  def new
    @folder = Folder.new
    add_breadcrumb "Folders", folders_path
    add_breadcrumb "New"
  end

  def create
    @folder = current_user.folders.build(folder_params)
    if @folder.save
      redirect_to folders_path, notice: "Folder created successfully."
    else
      render :new
    end
  end

  def edit
    add_breadcrumb "Folders", folders_path
    add_breadcrumb "Edit #{@folder.name}"
  end

  def update
    if @folder.update(folder_params)
      redirect_to folders_path, notice: "Folder updated successfully."
    else
      render :edit
    end
  end

  def destroy
    @folder.destroy
    redirect_to folders_path, notice: "Folder deleted successfully."
  end

  private

  def set_folder
    @folder = current_user.folders.find(params[:id])
  end

  def folder_params
    params.require(:folder).permit(:name)
  end
end
