class StoredFilesController < ApplicationController
  before_action :authenticate_user!

  def new
    @folder = current_user.folders.find(params[:folder_id])
    @stored_file = StoredFile.new
    add_breadcrumb "Folders", folders_path
    add_breadcrumb @folder.name, folder_path(@folder)
    add_breadcrumb "Upload New File"
  end
  
  # When it comes to uploading files, I had an issue where I was able to upload the file but when I attempted to download it back, it would not work. I believe this is because of the way that the file is being stored and retrieved from the database.
  def create
    @folder = current_user.folders.find(params[:folder_id])

    # Prevent empty uploads
    if stored_file_params[:uploaded_file].blank?
      redirect_to folder_path(@folder), alert: "Please choose a file before uploading." and return
    end

    @stored_file = @folder.stored_files.build(stored_file_params)
    @stored_file.user = current_user
    @stored_file.file_name = params.dig("stored_file", "uploaded_file")&.original_filename

    if @stored_file.save
      redirect_to folder_path(@folder), notice: "File uploaded successfully."
    else
      # What happens when the file fails to upload? Well the database will make the entry in the database but the file will not be uploaded to the cloud storage provider and this can lead to a lot of confusion for users because they will see the file in their folder but when they attempt to download it, it will not work. This is a critical flaw that needs to be addressed in order to provide a better user experience and prevent confusion for users. You could consider auto deleting the file entry in the database if the file fails to upload to the cloud storage provider or you could consider adding a status column to the database that indicates whether the file was successfully uploaded or not and then you could display a message to the user indicating that the file failed to upload and that they should try again. This would provide a better user experience and prevent confusion for users. It would also help to identify any issues with the cloud storage provider and allow you to address them more quickly.
      flash[:alert] = @stored_file.errors.full_messages.to_sentence
      render :new
    end
  end

  def destroy
    @stored_file = current_user.stored_files.find(params[:id])
    @stored_file.destroy
    redirect_to folder_path(@stored_file.folder), notice: "File deleted successfully."
  end

  def bulk_delete
    file_ids = params[:file_ids]

    if file_ids.present?
      files = current_user.stored_files.where(id: file_ids)
      folder = files.first.folder if files.any?

      files.destroy_all

      redirect_to folder_path(folder), notice: "Selected files deleted successfully."
    else
      redirect_back fallback_location: authenticated_root_path, alert: "No files selected."
    end
  end

  private

  def stored_file_params
    params.fetch(:stored_file, {}).permit(:uploaded_file)
  end
end
