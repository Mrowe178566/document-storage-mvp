require "rails_helper"

RSpec.describe "Workspace switching", type: :request do
  let(:setup_a) { create_owner_with_workspace(workspace_name: "Workspace A") }
  let(:user) { setup_a[0] }
  let(:workspace_a) { setup_a[1] }
  let!(:workspace_b) do
    Workspace.create!(name: "Workspace B").tap do |w|
      Membership.create!(user: user, workspace: w, role: "member")
    end
  end

  before { sign_in user }

  it "switches to a workspace the user belongs to" do
    post switch_workspace_path(workspace_b)

    expect(response).to redirect_to(authenticated_root_path)
    expect(session[:current_workspace_id]).to eq(workspace_b.id)
  end

  it "rejects switching to a workspace the user doesn't belong to" do
    other_workspace = Workspace.create!(name: "Outside")

    post switch_workspace_path(other_workspace)

    expect(session[:current_workspace_id]).not_to eq(other_workspace.id)
  end
end
