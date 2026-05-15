require "rails_helper"

RSpec.describe "Authentication", type: :feature do
  describe "sign up" do
    it "creates an account and a workspace owned by that user" do
      visit new_user_registration_path
      fill_in "Workspace name", with: "Maia Co."
      fill_in "Email address", with: "newuser@example.com"
      fill_in "Password", with: "password123"
      fill_in "Confirm password", with: "password123"
      click_button "Create account"

      expect(page).to have_content("Welcome to File Vault")

      user = User.find_by(email: "newuser@example.com")
      expect(user).to be_present
      expect(user.workspaces.count).to eq(1)
      workspace = user.workspaces.first
      expect(workspace.name).to eq("Maia Co.")
      expect(user.owner_of?(workspace)).to be(true)
    end

    it "rejects signup without a workspace name" do
      visit new_user_registration_path
      fill_in "Email address", with: "newuser@example.com"
      fill_in "Password", with: "password123"
      fill_in "Confirm password", with: "password123"
      click_button "Create account"

      expect(page).to have_content("can't be blank")
      expect(User.where(email: "newuser@example.com")).to be_empty
    end
  end

  describe "sign in" do
    it "allows an existing user to sign in" do
      create_owner_with_workspace(email: "test@example.com")

      visit new_user_session_path
      fill_in "Email address", with: "test@example.com"
      fill_in "Password", with: "password"
      click_button "Sign in"

      expect(page).to have_content("Signed in successfully")
    end
  end
end
