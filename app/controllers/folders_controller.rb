class FoldersController < ApplicationController
  before_action :authenticate_user!

  def index
    @folders = current_user.folders
    add_breadcrumb "Folders", folders_path
  end
  # You have two show methods here. You should remove one of them to avoid confusion and potential issues with routing. The second show method includes a search functionality that allows users to filter files within a folder based on a query parameter. 

  def new
    @folder = Folder.new
    add_breadcrumb "Folders", folders_path
    add_breadcrumb "new"
  end

  def create
    @folder = current_user.folders.build(folder_params)
    if @folder.save
      redirect_to folders_path, notice: "Folder created successfully."
    else
      render :new
    end
  end

  def destroy
    @folder = current_user.folders.find(params[:id])
    @folder.destroy
    redirect_to folders_path, notice: "Folder deleted successfully."
  end

  def show
    @folder = current_user.folders.find(params[:id])
    @files = @folder.stored_files

    if params[:query].present?
      @files = @files.where("file_name ILIKE ?", "%#{params[:query]}%")
    end

    add_breadcrumb "Folders", folders_path
    add_breadcrumb @folder.name
  end

  private

  def folder_params
    params.require(:folder).permit(:name)
  end
end
