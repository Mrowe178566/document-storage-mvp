require "rails_helper"

RSpec.describe Workspaces::Create do
  let(:user) { User.create!(email: "creator@example.com", password: "password") }

  describe ".call" do
    context "with a valid name" do
      it "creates the workspace" do
        expect {
          described_class.call(user: user, name: "Acme Inc.")
        }.to change(Workspace, :count).by(1)
      end

      it "makes the user the workspace owner" do
        result = described_class.call(user: user, name: "Acme Inc.")

        expect(result).to be_success
        expect(result.workspace).to be_persisted
        expect(result.workspace.name).to eq("Acme Inc.")
        expect(user.role_in(result.workspace)).to eq("owner")
      end

      it "trims surrounding whitespace from the name" do
        result = described_class.call(user: user, name: "  Acme Inc.  ")
        expect(result.workspace.name).to eq("Acme Inc.")
      end

      it "returns a Result with a nil error" do
        result = described_class.call(user: user, name: "Acme Inc.")
        expect(result.error).to be_nil
      end
    end

    context "with a blank name" do
      it "fails without creating anything" do
        expect {
          result = described_class.call(user: user, name: "   ")
          expect(result).not_to be_success
          expect(result.error).to match(/can't be blank/i)
          expect(result.workspace).to be_nil
        }.not_to change(Workspace, :count)
      end

      it "treats nil as blank" do
        result = described_class.call(user: user, name: nil)
        expect(result).not_to be_success
      end
    end

    context "when membership creation fails" do
      it "rolls back the workspace so we never leave an orphan" do
        # Force a Membership validation failure by making the user already
        # have a membership with that role on a workspace we're about to create
        # — easiest reproduction is to stub Membership to raise.
        allow(Membership).to receive(:create!).and_raise(
          ActiveRecord::RecordInvalid.new(Membership.new.tap { |m| m.errors.add(:base, "boom") })
        )

        expect {
          result = described_class.call(user: user, name: "Doomed Workspace")
          expect(result).not_to be_success
          expect(result.error).to match(/boom/)
        }.not_to change(Workspace, :count)
      end
    end
  end
end
