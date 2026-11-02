require "rails_helper"

# Walks the full forgot-password flow the way a user would:
#   browser -> route -> Devise::PasswordsController -> User model -> users table
#   -> reset email -> link back into the app -> new password saved -> signed in
RSpec.describe "Password reset", type: :feature do
  let(:setup) { create_owner_with_workspace(email: "maia@example.com") }
  let(:user)  { setup[0] }

  before { ActionMailer::Base.deliveries.clear }

  # Submits the "Forgot your password?" form and returns the raw token from the
  # email. The database only stores a hash of this token; the email has the real one.
  def request_reset_for(email)
    visit new_user_session_path
    click_link "Forgot your password?"

    fill_in "Email", with: email
    click_button "Send me reset password instructions"

    email_body = ActionMailer::Base.deliveries.last.body.encoded
    email_body[/reset_password_token=([^"&]+)/, 1]
  end

  def choose_new_password(token, password)
    visit edit_user_password_path(reset_password_token: token)
    fill_in "New password", with: password
    fill_in "Confirm your new password", with: password
    click_button "Change my password"
  end

  it "emails a reset link, sets the new password, and signs the user in" do
    token = request_reset_for(user.email)

    # Controller + mailer: one email, sent to the right person, with a token
    expect(page).to have_content("You will receive an email with instructions")
    expect(ActionMailer::Base.deliveries.size).to eq(1)
    expect(ActionMailer::Base.deliveries.last.to).to eq([ user.email ])
    expect(token).to be_present

    # Database: a hashed token and a timestamp were saved on the user
    expect(user.reload.reset_password_token).to be_present
    expect(user.reset_password_sent_at).to be_present

    choose_new_password(token, "brand-new-secret")

    # View: the user lands signed in
    expect(page).to have_content("Your password has been changed successfully. You are now signed in.")

    # Model: the new password works, the old one doesn't, and the token is cleared
    user.reload
    expect(user.valid_password?("brand-new-secret")).to be true
    expect(user.valid_password?("password")).to be false
    expect(user.reset_password_token).to be_nil
  end

  it "rejects a link older than the 6-hour window" do
    token = request_reset_for(user.email)

    # Pretend the email was sent 7 hours ago (devise.rb: reset_password_within = 6.hours)
    user.reload.update_column(:reset_password_sent_at, 7.hours.ago)

    choose_new_password(token, "brand-new-secret")

    expect(page).to have_content("has expired, please request a new one")
    expect(user.reload.valid_password?("password")).to be true
  end

  it "only lets a reset link be used once" do
    token = request_reset_for(user.email)
    choose_new_password(token, "brand-new-secret")

    Capybara.reset_session! # sign out, like opening the old email again later
    choose_new_password(token, "another-secret")

    expect(page).to have_content("Reset password token is invalid")
    expect(user.reload.valid_password?("brand-new-secret")).to be true
  end
end
