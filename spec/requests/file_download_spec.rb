require "rails_helper"

RSpec.describe "File downloads", type: :request do
  let(:user) { User.create!(email: "downloader@example.com", password: "password") }
  let(:folder) { user.workspace.folders.create!(name: "Docs", user: user) }
  let(:stored_file) do
    file = user.workspace.stored_files.build(file_name: "sample.pdf", user: user, folder: folder)
    file.uploaded_file.attach(
      io: File.open(Rails.root.join("spec/fixtures/files/sample.pdf")),
      filename: "sample.pdf",
      content_type: "application/pdf"
    )
    file.save!
    file
  end

  before { sign_in user }

  it "serves the stored file with attachment disposition" do
    get rails_blob_path(stored_file.uploaded_file, disposition: "attachment")
    expect(response).to have_http_status(:redirect)

    follow_redirect!
    expect(response).to have_http_status(:ok)
    expect(response.headers["Content-Disposition"]).to include("attachment")
    expect(response.headers["Content-Disposition"]).to include("sample.pdf")
  end
end
