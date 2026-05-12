require "rails_helper"

RSpec.describe "Invitation flow", type: :feature do
  let(:admin) { User.create!(email: "admin@example.com", password: "password") }
  let(:workspace) { admin.workspace }

  before { ActionMailer::Base.deliveries.clear }

  describe "as an admin" do
    before { sign_in admin }

    it "sends an invitation and shows it as pending in the workspace" do
      visit new_workspace_invitation_path
      fill_in "Email", with: "teammate@example.com"

      perform_enqueued_jobs do
        click_button "Send invitation"
      end

      expect(page).to have_content("Invitation sent to teammate@example.com")
      expect(page).to have_content("teammate@example.com")
      expect(page).to have_content("Pending invitations")

      invitation = workspace.invitations.last
      expect(invitation.email).to eq("teammate@example.com")
      expect(invitation.invited_by).to eq(admin)

      delivered = ActionMailer::Base.deliveries.last
      expect(delivered).to be_present
      expect(delivered.to).to eq([ "teammate@example.com" ])
      expect(delivered.subject).to include(workspace.name)
    end

    it "blocks invitations to emails that already have an account" do
      User.create!(email: "existing@example.com", password: "password")

      visit new_workspace_invitation_path
      fill_in "Email", with: "existing@example.com"
      click_button "Send invitation"

      expect(page).to have_content("An account already exists for existing@example.com")
      expect(workspace.invitations.where(email: "existing@example.com")).to be_empty
    end
  end

  describe "as the invitee" do
    let!(:invitation) do
      workspace.invitations.create!(email: "newcomer@example.com", invited_by: admin)
    end

    it "lets the invitee accept by setting a password and lands them in the workspace" do
      visit invitation_acceptance_path(token: invitation.token)

      fill_in "Password", with: "supersecret"
      fill_in "Confirm password", with: "supersecret"
      click_button "Accept invitation"

      expect(page).to have_content("Welcome to #{workspace.name}")

      new_user = User.find_by(email: "newcomer@example.com")
      expect(new_user).to be_present
      expect(new_user.workspace).to eq(workspace)
      expect(new_user.role).to eq("member")
      expect(invitation.reload).to be_accepted
    end

    it "rejects an expired invitation" do
      invitation.update!(expires_at: 1.day.ago)

      visit invitation_acceptance_path(token: invitation.token)

      expect(page).to have_content("That invitation has expired")
    end

    it "rejects an already-accepted invitation" do
      invitation.update!(accepted_at: Time.current)

      visit invitation_acceptance_path(token: invitation.token)

      expect(page).to have_content("already been accepted")
    end

    it "404s for an unknown token" do
      visit invitation_acceptance_path(token: "not-a-real-token")

      expect(page).to have_content("Invitation not found")
    end
  end
end
