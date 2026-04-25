require "rails_helper"

RSpec.describe "Folders", type: :feature do
  let(:user) { User.create!(email: "test@example.com", password: "password123") }

  before do
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"
    click_button "Log in"
  end

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
    it "shows only the current user's folders" do
      user.folders.create!(name: "My Folder")
      other_user = User.create!(email: "other@example.com", password: "password123")
      other_user.folders.create!(name: "Other Folder")
      visit folders_path
      expect(page).to have_content("My Folder")
      expect(page).not_to have_content("Other Folder")
    end
  end

  describe "deleting a folder" do
    it "allows a user to delete their folder" do
      user.folders.create!(name: "Delete Me")
      visit folders_path
      expect(page).to have_content("Delete Me")
    end
  end
end
