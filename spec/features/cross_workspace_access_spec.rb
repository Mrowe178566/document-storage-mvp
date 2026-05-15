require "rails_helper"

RSpec.describe "Cross-workspace access is blocked", type: :feature do
  let(:setup_a) { create_owner_with_workspace(email: "owner@example.com", workspace_name: "Owner WS") }
  let(:owner) { setup_a[0] }
  let(:owners_workspace) { setup_a[1] }
  let(:owners_folder) { owners_workspace.folders.create!(name: "Owner private", user: owner) }
  let(:owners_file) do
    file = owners_workspace.stored_files.build(file_name: "secret.pdf", user: owner, folder: owners_folder)
    file.uploaded_file.attach(
      io: File.open(Rails.root.join("spec/fixtures/files/sample.pdf")),
      filename: "secret.pdf",
      content_type: "application/pdf"
    )
    file.save!
    file
  end

  let(:setup_b) { create_owner_with_workspace(email: "outsider@example.com", workspace_name: "Outsider WS") }
  let(:outsider) { setup_b[0] }

  before do
    owners_folder
    sign_in outsider
  end

  it "does not list folders that belong to other workspaces" do
    visit folders_path
    expect(page).not_to have_content("Owner private")
  end

  it "returns 404 when an outsider tries to view a folder in another workspace" do
    visit folder_path(owners_folder)
    expect(page.status_code).to eq(404)
  end

  it "returns 404 when an outsider tries to delete a file in another workspace" do
    file = owners_file
    page.driver.submit :delete, stored_file_path(file), {}
    expect(page.status_code).to eq(404)
    expect(StoredFile.exists?(file.id)).to be(true)
  end
end
