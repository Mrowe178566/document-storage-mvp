require "rails_helper"

# File access is checked on every request: sign-in, workspace, role, and the
# folder's permissions. Files are only reachable through the app's own
# download action, never through Active Storage's built-in blob URLs.
RSpec.describe "File access", type: :request do
  let(:setup)     { create_owner_with_workspace(email: "owner@example.com") }
  let(:owner)     { setup[0] }
  let(:workspace) { setup[1] }
  let(:member)    { create_member(workspace, email: "member@example.com", role: "member") }
  let(:granted)   { create_member(workspace, email: "granted@example.com", role: "member") }
  let(:viewer)    { create_member(workspace, email: "viewer@example.com", role: "viewer") }
  let(:outsider)  { create_owner_with_workspace(email: "outsider@example.com")[0] }

  let(:open_folder) { workspace.folders.create!(name: "Shared", user: owner) }
  let(:restricted_folder) do
    workspace.folders.create!(name: "HR only", user: owner).tap do |folder|
      folder.folder_permissions.create!(user: granted)
    end
  end

  let!(:open_file)       { store_file(open_folder, name: "handbook.txt", body: "open contents") }
  let!(:restricted_file) { store_file(restricted_folder, name: "salaries.txt", body: "secret contents") }

  def store_file(folder, name:, body:)
    folder.stored_files.create!(
      workspace: folder.workspace, user: folder.user, file_name: name,
      uploaded_file: { io: StringIO.new(body), filename: name, content_type: "text/plain" }
    )
  end

  def expect_file_sent(file, body)
    expect(response).to have_http_status(:ok)
    expect(response.headers["Content-Disposition"]).to include("attachment")
    expect(response.headers["Content-Disposition"]).to include(file.file_name)
    expect(response.body).to eq(body)
  end

  describe "downloading" do
    # App routes live inside `authenticated :user`, so signed-out visitors get
    # a 404 rather than a redirect. Either way, no file is sent.
    it "requires sign-in" do
      get download_stored_file_path(open_file)

      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include("open contents")
    end

    it "sends the file to a member of the workspace" do
      sign_in member
      get download_stored_file_path(open_file)

      expect_file_sent(open_file, "open contents")
    end

    it "lets viewers download" do
      sign_in viewer
      get download_stored_file_path(open_file)

      expect_file_sent(open_file, "open contents")
    end

    it "returns not found for someone in a different workspace" do
      sign_in outsider
      get download_stored_file_path(open_file)

      expect(response).to have_http_status(:not_found)
    end

    it "blocks a member who wasn't granted access to a restricted folder" do
      sign_in member
      get download_stored_file_path(restricted_file)

      expect(response).to redirect_to(authenticated_root_path)
      expect(response.body).not_to include("secret contents")
    end

    it "allows a member who was granted access to a restricted folder" do
      sign_in granted
      get download_stored_file_path(restricted_file)

      expect_file_sent(restricted_file, "secret contents")
    end

    it "allows admins and owners into restricted folders" do
      sign_in owner
      get download_stored_file_path(restricted_file)

      expect_file_sent(restricted_file, "secret contents")
    end
  end

  describe "Active Storage's built-in blob URLs" do
    it "are switched off, so old or leaked links stop working" do
      blob = restricted_file.uploaded_file.blob
      get "/rails/active_storage/blobs/redirect/#{blob.signed_id}/#{blob.filename}"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "changing files in a restricted folder without access" do
    before { sign_in member }

    it "can't delete a file" do
      expect { delete stored_file_path(restricted_file) }.not_to change(StoredFile, :count)
    end

    it "can't bulk-delete it, and only deletes the files they can access" do
      expect {
        delete bulk_delete_stored_files_path, params: { file_ids: [ open_file.id, restricted_file.id ] }
      }.to change(StoredFile, :count).by(-1)

      expect(StoredFile.exists?(restricted_file.id)).to be true
      expect(StoredFile.exists?(open_file.id)).to be false
    end

    it "can't upload into it" do
      upload = Rack::Test::UploadedFile.new(StringIO.new("planted"), "text/plain", original_filename: "planted.txt")

      expect {
        post stored_files_path, params: { folder_id: restricted_folder.id, stored_file: { uploaded_file: upload } }
      }.not_to change(StoredFile, :count)
    end
  end

  describe "the folder page" do
    it "links downloads through the app, not Active Storage" do
      sign_in member
      get folder_path(open_folder)

      expect(response.body).to include(download_stored_file_path(open_file))
      expect(response.body).not_to include("/rails/active_storage")
    end
  end
end
