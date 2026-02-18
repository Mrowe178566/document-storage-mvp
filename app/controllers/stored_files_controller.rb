class StoredFilesController < ApplicationController
  before_action :authenticate_user!

  def new
    @folder = current_user.folders.find(params[:folder_id])
    @stored_file = StoredFile.new
  end

  def create
    @folder = current_user.folders.find(params[:stored_file][:folder_id])
    @stored_file = @folder.stored_files.build(stored_file_params)
    @stored_file.user = current_user

    if @stored_file.save
      redirect_to folder_path(@folder), notice: "File uploaded successfully."
    else
      render :new
    end
  end

  private

  def stored_file_params
    params.require(:stored_file).permit(:folder_id, :uploaded_file)
  end
end
