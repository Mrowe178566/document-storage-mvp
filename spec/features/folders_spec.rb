require "rails_helper"

RSpec.describe "Folders", type: :feature do
  let(:setup) { create_owner_with_workspace(email: "test@example.com") }
  let(:user) { setup[0] }
  let(:workspace) { setup[1] }

  before { sign_in user }

  describe "creating a folder" do
    it "allows a user to create a folder" do
      visit new_folder_path
      fill_in "Name", with: "My Test Folder"
      click_button "Create Folder"
      expect(page).to have_content("Folder created successfully")
      expect(page).to have_content("My Test Folder")
    end
  end

  describe "viewing folders" do
    it "shows only the current workspace's folders" do
      workspace.folders.create!(name: "My Folder", user: user)

      _, other_workspace = create_owner_with_workspace(
        email: "other@example.com",
        workspace_name: "Other Workspace"
      )
      other_user = other_workspace.users.first
      other_workspace.folders.create!(name: "Other Folder", user: other_user)

      visit folders_path
      expect(page).to have_content("My Folder")
      expect(page).not_to have_content("Other Folder")
    end
  end
end
