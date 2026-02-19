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
    @stored_file.file_name = params.dig("stored_file", "uploaded_file")&.original_filename

    if @stored_file.save
      redirect_to folder_path(@folder), notice: "File uploaded successfully."
    else
      flash[:alert] = @stored_file.errors.full_messages.to_sentence
      render :new
    end
  end

  def destroy
    @stored_file = current_user.stored_files.find(params[:id])
    @stored_file.destroy
    redirect_to folder_path(@stored_file.folder), notice: "File deleted successfully."
  end

  private

  def stored_file_params
    params.require(:stored_file).permit(:folder_id, :uploaded_file)
  end
end
