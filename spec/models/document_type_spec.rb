require "rails_helper"

RSpec.describe DocumentType, type: :model do
  let(:setup)     { create_owner_with_workspace }
  let(:owner)     { setup[0] }
  let(:workspace) { setup[1] }

  def build_type(**attrs)
    workspace.document_types.build({ name: "Insurance certificate" }.merge(attrs))
  end

  describe "associations" do
    it { should belong_to(:workspace) }
    it { should have_many(:stored_files).dependent(:nullify) }
  end

  describe "name" do
    it "is required" do
      type = build_type(name: "  ")
      expect(type).not_to be_valid
      expect(type.errors[:name]).to include("can't be blank")
    end

    it "is trimmed and has extra spaces collapsed" do
      expect(build_type(name: "  Tax   form  ").name).to eq("Tax form")
    end

    it "is unique within a workspace, ignoring case" do
      build_type(name: "Training record").save!
      duplicate = build_type(name: "training RECORD")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("is already used by another document type")
    end

    it "can repeat across different workspaces" do
      build_type(name: "Training record").save!
      _, other_workspace = create_owner_with_workspace(workspace_name: "Other")
      expect(other_workspace.document_types.build(name: "Training record")).to be_valid
    end

    it "is also unique at the database level" do
      build_type(name: "Training record").save!
      copy = build_type(name: "TRAINING RECORD")
      expect { copy.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "a type that expires" do
    it "needs a number of months it stays valid" do
      type = build_type(expires: true, valid_for_months: nil, remind_days_before: 30)
      expect(type).not_to be_valid
      expect(type.errors[:valid_for_months]).to include("can't be blank")
    end

    it "needs at least one month" do
      type = build_type(expires: true, valid_for_months: 0, remind_days_before: 30)
      expect(type).not_to be_valid
      expect(type.errors[:valid_for_months]).to be_present
    end

    it "caps the valid period at ten years" do
      type = build_type(expires: true, valid_for_months: 121, remind_days_before: 30)
      expect(type).not_to be_valid
      expect(type.errors[:valid_for_months]).to be_present
    end

    it "needs a reminder lead time of zero or more days" do
      expect(build_type(expires: true, valid_for_months: 12, remind_days_before: nil)).not_to be_valid
      expect(build_type(expires: true, valid_for_months: 12, remind_days_before: -1)).not_to be_valid
      expect(build_type(expires: true, valid_for_months: 12, remind_days_before: 0)).to be_valid
    end

    it "caps the reminder lead time at one year" do
      expect(build_type(expires: true, valid_for_months: 36, remind_days_before: 366)).not_to be_valid
    end

    it "keeps its settings when saved" do
      type = build_type(expires: true, valid_for_months: 12, remind_days_before: 30)
      type.save!
      expect(type.reload).to have_attributes(valid_for_months: 12, remind_days_before: 30)
    end
  end

  describe "a type that never expires" do
    it "drops any leftover expiry settings so they can't be used by mistake" do
      type = build_type(expires: false, valid_for_months: 12, remind_days_before: 30)
      type.save!
      expect(type.reload).to have_attributes(valid_for_months: nil, remind_days_before: nil)
    end

    it "is refused by the database if expiry settings sneak in" do
      type = build_type(expires: false)
      type.save!
      expect {
        type.update_columns(valid_for_months: 12)
      }.to raise_error(ActiveRecord::StatementInvalid, /document_types_expiry_settings/)
    end
  end

  it "is refused by the database when it expires without a valid period" do
    type = build_type(expires: false)
    type.save!
    expect {
      type.update_columns(expires: true)
    }.to raise_error(ActiveRecord::StatementInvalid, /document_types_expiry_settings/)
  end

  describe "#expires_on_for" do
    it "adds the valid period to the date the document was issued" do
      type = build_type(expires: true, valid_for_months: 12, remind_days_before: 30)
      expect(type.expires_on_for(Date.new(2026, 11, 2))).to eq(Date.new(2027, 11, 2))
    end

    it "handles month ends without spilling into the next month" do
      type = build_type(expires: true, valid_for_months: 1, remind_days_before: 7)
      expect(type.expires_on_for(Date.new(2027, 1, 31))).to eq(Date.new(2027, 2, 28))
    end

    it "returns nil for a type that never expires" do
      expect(build_type(expires: false).expires_on_for(Date.new(2026, 11, 2))).to be_nil
    end
  end

  describe "#remind_on_for" do
    it "is the expiry date minus the reminder lead time" do
      type = build_type(expires: true, valid_for_months: 12, remind_days_before: 30)
      expect(type.remind_on_for(Date.new(2026, 11, 2))).to eq(Date.new(2027, 10, 3))
    end

    it "returns nil for a type that never expires" do
      expect(build_type(expires: false).remind_on_for(Date.new(2026, 11, 2))).to be_nil
    end
  end

  it "lists types alphabetically with .by_name" do
    build_type(name: "Tax form").save!
    build_type(name: "insurance certificate").save!
    build_type(name: "Material test report").save!
    expect(workspace.document_types.by_name.map(&:name))
      .to eq([ "insurance certificate", "Material test report", "Tax form" ])
  end
end
