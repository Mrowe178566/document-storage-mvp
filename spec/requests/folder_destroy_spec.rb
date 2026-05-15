require "rails_helper"

RSpec.describe "Deleting folders", type: :request do
  let(:setup) { create_owner_with_workspace(email: "owner@example.com") }
  let(:user) { setup[0] }
  let(:workspace) { setup[1] }
  let(:folder) { workspace.folders.create!(name: "Trash me", user: user) }

  before { sign_in user }

  it "lets the owner delete a folder in their workspace" do
    folder
    expect {
      delete folder_path(folder)
    }.to change { Folder.count }.by(-1)

    expect(response).to redirect_to(folders_path)
    expect(Folder.exists?(folder.id)).to be(false)
  end

  it "cascades deletion to stored files in the folder" do
    file = workspace.stored_files.build(file_name: "doc.pdf", user: user, folder: folder)
    file.uploaded_file.attach(
      io: File.open(Rails.root.join("spec/fixtures/files/sample.pdf")),
      filename: "doc.pdf",
      content_type: "application/pdf"
    )
    file.save!

    delete folder_path(folder)

    expect(StoredFile.exists?(file.id)).to be(false)
  end
end
