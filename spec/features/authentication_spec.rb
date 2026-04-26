require "rails_helper"

RSpec.describe "Authentication", type: :feature do
  describe "sign up" do
    it "allows a new user to create an account" do
      visit new_user_registration_path
      fill_in "Email address", with: "newuser@example.com"
      fill_in "Password", with: "password123"
      fill_in "Confirm password", with: "password123"
      click_button "Create account"
      expect(page).to have_content("Welcome")
    end
  end

  describe "sign in" do
    it "allows an existing user to sign in" do
      User.create!(email: "test@example.com", password: "password123")
      visit new_user_session_path
      fill_in "Email address", with: "test@example.com"
      fill_in "Password", with: "password123"
      click_button "Sign in"
      expect(page).to have_content("Signed in successfully")
    end
  end
end
