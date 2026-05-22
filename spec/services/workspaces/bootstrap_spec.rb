require "rails_helper"

RSpec.describe Workspaces::Bootstrap do
  let(:setup) { create_owner_with_workspace(email: "owner@example.com") }
  let(:owner) { setup[0] }
  let(:workspace) { setup[1] }

  describe ".call" do
    context "on an empty workspace" do
      it "creates the full manufacturing starter set" do
        expect {
          described_class.call(workspace: workspace, user: owner)
        }.to change(workspace.folders, :count).by(Workspaces::Bootstrap::MANUFACTURING_FOLDERS.size)
      end

      it "returns a Result listing the folders it created" do
        result = described_class.call(workspace: workspace, user: owner)

        expect(result).to be_success
        expect(result.folders.map(&:name)).to match_array(Workspaces::Bootstrap::MANUFACTURING_FOLDERS)
        expect(result.error).to be_nil
      end

      it "attributes each folder to the bootstrapping user" do
        result = described_class.call(workspace: workspace, user: owner)
        expect(result.folders).to all(have_attributes(user: owner))
      end
    end

    context "when run a second time (idempotency)" do
      before { described_class.call(workspace: workspace, user: owner) }

      it "doesn't duplicate any folders" do
        expect {
          described_class.call(workspace: workspace, user: owner)
        }.not_to change(workspace.folders, :count)
      end

      it "returns success with an empty created list" do
        result = described_class.call(workspace: workspace, user: owner)
        expect(result).to be_success
        expect(result.folders).to be_empty
      end
    end

    context "when only some starter folders are missing" do
      before do
        workspace.folders.create!(name: "Quality Control", user: owner)
      end

      it "creates only the missing ones" do
        result = described_class.call(workspace: workspace, user: owner)
        expect(result.folders.size).to eq(Workspaces::Bootstrap::MANUFACTURING_FOLDERS.size - 1)
        expect(result.folders.map(&:name)).not_to include("Quality Control")
      end
    end

    context "with a custom folder list" do
      it "uses the override instead of the manufacturing default" do
        result = described_class.call(workspace: workspace, user: owner, folder_names: [ "Alpha", "Beta" ])
        expect(result.folders.map(&:name)).to match_array([ "Alpha", "Beta" ])
      end
    end

    context "when folder creation fails" do
      it "rolls back the whole transaction" do
        allow(workspace.folders).to receive(:create!).and_raise(
          ActiveRecord::RecordInvalid.new(Folder.new.tap { |f| f.errors.add(:name, "boom") })
        )
        # Re-fetch via the workspace association so the stub takes effect
        allow(Workspace).to receive(:find).and_return(workspace)

        expect {
          result = described_class.call(workspace: workspace, user: owner)
          expect(result).not_to be_success
        }.not_to change(Folder, :count)
      end
    end
  end
end
