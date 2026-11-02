require "rails_helper"

# Dashboard and Folders are separate pages. The sidebar used to send both
# links to the same page, so clicking Folders looked like it did nothing.
RSpec.describe "Dashboard and Folders pages", type: :feature do
  let(:setup)     { create_owner_with_workspace(email: "owner@example.com", workspace_name: "Warehouse") }
  let(:owner)     { setup[0] }
  let(:workspace) { setup[1] }

  def active_nav_item
    find("a.fv-nav-item.active")
  end

  context "with folders" do
    before do
      workspace.folders.create!(name: "Invoices", user: owner)
      workspace.folders.create!(name: "Contracts", user: owner)
      sign_in owner
    end

    it "opens the dashboard after sign-in, with Dashboard highlighted" do
      visit authenticated_root_path

      expect(page).to have_css("h1", text: "Warehouse")
      expect(page).to have_content("Recent activity")
      expect(page).to have_link("View all folders", href: folders_path)
      expect(active_nav_item).to have_text("Dashboard")
    end

    it "opens the folder list from the sidebar, with Folders highlighted" do
      visit authenticated_root_path
      within(".fv-sidebar-nav") { click_link "Folders" }

      expect(page).to have_current_path(folders_path)
      expect(page).to have_css("h1", text: "Folders")
      expect(page).to have_link("Invoices", href: folder_path(workspace.folders.find_by!(name: "Invoices")))
      expect(page).to have_link("Contracts")
      expect(page).not_to have_content("Recent activity")
      expect(active_nav_item).to have_text("Folders")
    end

    it "keeps Folders highlighted inside a folder" do
      visit folder_path(workspace.folders.first)

      expect(active_nav_item).to have_text("Folders")
    end

    it "returns to the folder list after creating a folder" do
      visit folders_path
      click_link "New folder"
      fill_in "Name", with: "Receipts"
      click_button "Create Folder"

      expect(page).to have_current_path(folders_path)
      expect(page).to have_link("Receipts")
    end
  end

  context "with no folders" do
    before { sign_in owner }

    it "shows an empty folder list with a way to add one" do
      visit folders_path

      expect(page).to have_content("No folders yet")
      expect(page).to have_link("New folder", href: new_folder_path)
    end
  end

  context "as a member without access to a restricted folder" do
    let(:member) { create_member(workspace, email: "member@example.com", role: "member") }

    before do
      workspace.folders.create!(name: "Shared", user: owner)
      workspace.folders.create!(name: "HR only", user: owner).folder_permissions.create!(user: owner)
      sign_in member
    end

    it "lists only the folders they can open" do
      visit folders_path

      expect(page).to have_link("Shared")
      expect(page).not_to have_content("HR only")
    end
  end
end
