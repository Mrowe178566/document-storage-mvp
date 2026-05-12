require "rails_helper"

RSpec.describe "Uploading files", type: :feature do
  let(:user) { User.create!(email: "uploader@example.com", password: "password") }
  let(:folder) { user.workspace.folders.create!(name: "Docs", user: user) }
  let(:fixture_path) { Rails.root.join("spec/fixtures/files/sample.pdf") }

  before { sign_in user }

  it "uploads a file into a folder and shows it in the listing" do
    visit folder_path(folder)
    attach_file "stored_file[uploaded_file]", fixture_path
    click_button "Upload"

    expect(page).to have_content("File uploaded successfully")
    expect(page).to have_content("sample.pdf")
    expect(folder.stored_files.reload.count).to eq(1)

    uploaded = folder.stored_files.last
    expect(uploaded.user).to eq(user)
    expect(uploaded.workspace).to eq(user.workspace)
    expect(uploaded.uploaded_file).to be_attached
  end

  it "shows an alert when no file is selected" do
    visit folder_path(folder)
    click_button "Upload"
    expect(page).to have_content("Please choose a file before uploading.")
    expect(folder.stored_files.reload.count).to eq(0)
  end
end
