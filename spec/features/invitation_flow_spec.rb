require "rails_helper"

RSpec.describe "Invitation flow", type: :feature do
  let(:setup) { create_owner_with_workspace(email: "admin@example.com") }
  let(:admin) { setup[0] }
  let(:workspace) { setup[1] }

  before { ActionMailer::Base.deliveries.clear }

  describe "as an admin sending invitations" do
    before { sign_in admin }

    it "sends an invitation and shows it as pending in the workspace" do
      visit new_workspace_invitation_path
      fill_in "Email", with: "teammate@example.com"

      perform_enqueued_jobs do
        click_button "Send invitation"
      end

      expect(page).to have_content("Invitation sent to teammate@example.com")
      expect(page).to have_content("Pending invitations")

      invitation = workspace.invitations.last
      expect(invitation.email).to eq("teammate@example.com")
      expect(invitation.invited_by).to eq(admin)

      delivered = ActionMailer::Base.deliveries.last
      expect(delivered).to be_present
      expect(delivered.to).to eq([ "teammate@example.com" ])
    end

    it "allows sending an invitation to an email that already has an account" do
      User.create!(email: "existing@example.com", password: "password")

      visit new_workspace_invitation_path
      fill_in "Email", with: "existing@example.com"
      click_button "Send invitation"

      expect(page).to have_content("Invitation sent to existing@example.com")
      expect(workspace.invitations.find_by(email: "existing@example.com")).to be_present
    end

    it "blocks invitations to someone already a member of this workspace" do
      teammate = create_member(workspace, email: "teammate@example.com", role: "member")

      visit new_workspace_invitation_path
      fill_in "Email", with: teammate.email
      click_button "Send invitation"

      expect(page).to have_content("already a member of this workspace")
      expect(workspace.invitations.where(email: teammate.email)).to be_empty
    end
  end

  describe "as a brand-new invitee" do
    let!(:invitation) do
      workspace.invitations.create!(email: "newcomer@example.com", invited_by: admin)
    end

    it "lets them set a password and lands them in the workspace" do
      visit invitation_acceptance_path(token: invitation.token)

      fill_in "Password", with: "supersecret"
      fill_in "Confirm password", with: "supersecret"
      click_button "Accept invitation"

      expect(page).to have_content("Welcome to #{workspace.name}")

      new_user = User.find_by(email: "newcomer@example.com")
      expect(new_user).to be_present
      expect(new_user.workspaces).to include(workspace)
      expect(new_user.role_in(workspace)).to eq("member")
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

  describe "as an existing-account invitee" do
    let(:existing_user) { User.create!(email: "existing@example.com", password: "password") }
    let!(:invitation) do
      workspace.invitations.create!(email: "existing@example.com", invited_by: admin)
    end

    it "shows a 'Join workspace' confirm page when signed in as the invitee" do
      sign_in existing_user
      visit invitation_acceptance_path(token: invitation.token)

      expect(page).to have_content("Join #{workspace.name}?")
      expect(page).to have_content(existing_user.email)

      click_button "Join workspace"

      expect(page).to have_content("You joined #{workspace.name}")
      expect(existing_user.reload.workspaces).to include(workspace)
      expect(existing_user.role_in(workspace)).to eq("member")
      expect(invitation.reload).to be_accepted
    end

    it "redirects to sign-in when not signed in" do
      visit invitation_acceptance_path(token: invitation.token)

      expect(current_path).to eq(new_user_session_path)
      expect(page).to have_content("Sign in to accept your invitation to #{workspace.name}")
    end

    it "rejects when signed in as a different user" do
      other_user = create_owner_with_workspace(email: "other@example.com", workspace_name: "Other WS")[0]
      sign_in other_user

      visit invitation_acceptance_path(token: invitation.token)

      expect(page).to have_content("This invitation is for existing@example.com")
      expect(existing_user.reload.workspaces).not_to include(workspace)
    end
  end
end
