class StoredFilesController < ApplicationController
  before_action :authenticate_user!

  def create
    folder_id = params[:folder_id] || params.dig(:stored_file, :folder_id)
    @folder = current_workspace.folders.find(folder_id)

    if stored_file_params[:uploaded_file].blank?
      redirect_to folder_path(@folder), alert: "Please choose a file before uploading." and return
    end

    @stored_file = @folder.stored_files.build(stored_file_params)
    @stored_file.workspace = current_workspace
    @stored_file.user = current_user
    @stored_file.file_name = params.dig("stored_file", "uploaded_file")&.original_filename

    if @stored_file.save
      redirect_to folder_path(@folder), notice: "File uploaded successfully."
    else
      redirect_to folder_path(@folder), alert: @stored_file.errors.full_messages.to_sentence
    end
  end

  def destroy
    @stored_file = current_workspace.stored_files.find(params[:id])
    @stored_file.destroy
    redirect_to folder_path(@stored_file.folder), notice: "File deleted successfully."
  end

  def bulk_delete
    file_ids = params[:file_ids]
    if file_ids.present?
      files = current_workspace.stored_files.where(id: file_ids)
      folder = files.first&.folder
      files.destroy_all
      redirect_to folder ? folder_path(folder) : authenticated_root_path,
                  notice: "Selected files deleted successfully."
    else
      redirect_back_or_to authenticated_root_path, alert: "No files selected."
    end
  end

  private

  def stored_file_params
    params.fetch(:stored_file, {}).permit(:uploaded_file)
  end
end
