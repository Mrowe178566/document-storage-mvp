require "rails_helper"

RSpec.describe "Authentication", type: :feature do
  describe "sign up" do
    it "allows a new user to create an account" do
      visit new_user_registration_path
      fill_in "Email", with: "newuser@example.com"
      fill_in "Password", with: "password123"
      fill_in "Password confirmation", with: "password123"
      click_button "Sign up"
      expect(page).to have_content("Welcome")
    end
  end

  describe "sign in" do
    it "allows an existing user to sign in" do
      User.create!(email: "test@example.com", password: "password123")
      visit new_user_session_path
      fill_in "Email", with: "test@example.com"
      fill_in "Password", with: "password123"
      click_button "Log in"
      expect(page).to have_content("Signed in successfully")
    end
  end
end
