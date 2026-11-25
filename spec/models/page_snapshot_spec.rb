require "rails_helper"

RSpec.describe PageSnapshot do
  subject(:page_snapshot) { build(:page_snapshot) }

  it { is_expected.to be_valid }

  describe "associations" do
    it { is_expected.to belong_to(:audit) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:kind).with_values(home: "home", accessibility: "accessibility").backed_by_column_of_type(:string) }
  end

  describe "#auditable?" do
    it "is true for a successful response" do
      expect(build(:page_snapshot, status: 200)).to be_auditable
    end

    it "is false for an HTTP error" do
      expect(build(:page_snapshot, status: 404)).not_to be_auditable
    end
  end
end
