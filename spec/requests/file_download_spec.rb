require "rails_helper"

RSpec.describe "File downloads", type: :request do
  let(:setup) { create_owner_with_workspace(email: "downloader@example.com") }
  let(:user) { setup[0] }
  let(:workspace) { setup[1] }
  let(:folder) { workspace.folders.create!(name: "Docs", user: user) }
  let(:stored_file) do
    file = workspace.stored_files.build(file_name: "sample.pdf", user: user, folder: folder)
    file.uploaded_file.attach(
      io: File.open(Rails.root.join("spec/fixtures/files/sample.pdf")),
      filename: "sample.pdf",
      content_type: "application/pdf"
    )
    file.save!
    file
  end

  before { sign_in user }

  it "sends the stored file through the app as an attachment" do
    get download_stored_file_path(stored_file)

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/pdf")
    expect(response.headers["Content-Disposition"]).to include("attachment")
    expect(response.headers["Content-Disposition"]).to include("sample.pdf")
    expect(response.body.b).to eq(File.binread(Rails.root.join("spec/fixtures/files/sample.pdf")))
  end
end
