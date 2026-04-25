require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it { should have_many(:folders).dependent(:destroy) }
    it { should have_many(:stored_files).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:email) }
  end
end
